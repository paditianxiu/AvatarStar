"""Read PDE directories with the client's actual Win32 signed seek convention."""
import ctypes
from ctypes import wintypes as w
import hashlib
import json
from pathlib import Path
import struct
import sys

kernel = ctypes.WinDLL('kernel32', use_last_error=True)
kernel.CreateFileW.argtypes = [w.LPCWSTR, w.DWORD, w.DWORD, w.LPVOID, w.DWORD, w.DWORD, w.HANDLE]
kernel.CreateFileW.restype = w.HANDLE
kernel.SetFilePointer.argtypes = [w.HANDLE, w.LONG, ctypes.POINTER(w.LONG), w.DWORD]
kernel.SetFilePointer.restype = w.DWORD
kernel.ReadFile.argtypes = [w.HANDLE, w.LPVOID, w.DWORD, ctypes.POINTER(w.DWORD), w.LPVOID]
kernel.ReadFile.restype = w.BOOL
kernel.CloseHandle.argtypes = [w.HANDLE]

key = bytearray()
seed = 0x42574954
for _ in range(4096):
    seed = seed * 0x7fcf & 0xffffffff
    key.append((seed ^ (seed >> 8) ^ (seed >> 16) ^ (seed >> 24)) & 255)


def verify(filename):
    filename = Path(filename).resolve()
    size = filename.stat().st_size
    if size >= 0x80000000:
        raise ValueError(f'{filename}: exceeds native signed seek limit')
    handle = kernel.CreateFileW(str(filename), 0x80000000, 7, None, 3, 128, None)
    if handle == w.HANDLE(-1).value:
        raise ctypes.WinError(ctypes.get_last_error())
    reads, files, dirs, maximum = 0, 0, 0, 0
    tables, names, visited = {}, {}, set()

    def read(offset, length):
        nonlocal reads, maximum
        if offset < 0 or offset + length > size:
            raise ValueError('Out-of-bounds PDE read')
        # Exactly SetFilePointer(handle, signed_offset, NULL, FILE_BEGIN), as
        # client.exe sub_C36D60. A 64-bit FileStream would miss this failure.
        ctypes.set_last_error(0)
        result = kernel.SetFilePointer(handle, offset, None, 0)
        if result == 0xffffffff:
            raise ctypes.WinError(ctypes.get_last_error())
        buffer = ctypes.create_string_buffer(length)
        received = w.DWORD()
        if not kernel.ReadFile(handle, buffer, length, ctypes.byref(received), None):
            raise ctypes.WinError(ctypes.get_last_error())
        if received.value != length:
            raise ValueError('Short native read')
        reads += 1
        maximum = max(maximum, offset + length)
        return bytes(v ^ key[(offset + i) % 4096] for i, v in enumerate(buffer.raw))

    def real(block):
        return (block + block // 1024 + 1) * 4096

    def chain(block, length):
        seen = set()
        while length > 0:
            if block in seen:
                raise ValueError('Cyclic PDE chain')
            seen.add(block)
            yield block, min(length, 4096)
            length -= 4096
            if length <= 0:
                break
            group = block // 1024
            if group not in tables:
                tables[group] = read(group * 0x401000, 4096)
            raw = struct.unpack_from('<I', tables[group], block % 1024 * 4)[0]
            if not raw & 0x80000000:
                raise ValueError('Unallocated PDE chain block')
            block = raw & 0x7fffffff

    def payload(block, length):
        return b''.join(read(real(b), n) for b, n in chain(block, length))

    def visit(block, length, prefix=''):
        nonlocal dirs, files
        if block in visited:
            raise ValueError('Repeated directory block')
        visited.add(block)
        dirs += 1
        data = payload(block, length)
        for offset in range(0, len(data), 128):
            kind = data[offset]
            if kind not in (1, 2):
                continue
            name = data[offset + 1:offset + 112].split(b'\0', 1)[0].decode('utf-8')
            name = prefix + name
            start, count = struct.unpack_from('<II', data, offset + 120)
            if kind == 2:
                visit(start, count, name + '/')
            else:
                files += 1
                blocks = list(chain(start, count))
                if any(real(b) + n > size for b, n in blocks):
                    raise ValueError('Invalid file chain: ' + name)
                # Read the final block of every file through the native API.
                # Together with the signed size bound this checks far resources.
                if blocks:
                    last, amount = blocks[-1]
                    read(real(last), amount)
                if name.lower() in ('scripts/newsys/custommaps.lua', 'finalcombat/actors.mounted'):
                    names[name] = hashlib.sha256(payload(start, count)).hexdigest()

    try:
        visit(0, 4096)
        return dict(path=str(filename), bytes=size, files=files, directories=dirs,
                    nativeReads=reads, greatestReadEnd=maximum, resources=names)
    finally:
        kernel.CloseHandle(handle)


if __name__ == '__main__':
    print(json.dumps([verify(filename) for filename in sys.argv[1:]], indent=2))
