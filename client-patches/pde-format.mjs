import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const thai = /[\u0e00-\u0e7f]/u;
const utf8 = new TextDecoder('utf-8', { fatal: true });
export const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

export function decodeCache(bytes, stripHeader = true) {
  let base = 12;
  const dependencies = bytes.readUInt32LE(8);
  for (let i = 0; i < dependencies; i++) {
    const size = bytes.readUInt32LE(base);
    base += 4 + size + 8;
  }
  const flag = bytes[base + 12];
  if (flag === 0x6e) return bytes.subarray(base + (stripHeader ? 29 : 21));
  if (flag !== 0x6f && flag !== 0x6d) throw new Error(`Unknown cache flag ${flag}`);
  const length = flag === 0x6f ? bytes.readUInt32LE(base + 17) : bytes[base + 14];
  if (length > 100_000_000) throw new Error('Invalid cache output size');
  const src = bytes.subarray(base + (flag === 0x6f ? 21 : 15));
  const out = Buffer.alloc(length);
  const shifts = [4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0];
  let bits = 1, input = 0, output = 0;
  while (output < length) {
    if (bits === 1) { bits = src.readUInt32LE(input); input += 4; }
    if (input + 4 > src.length) break;
    const value = src.readUInt32LE(input);
    if (!(bits & 1)) {
      if (output >= length - 10) break;
      const count = shifts[bits & 15];
      src.copy(out, output, input, input + count);
      output += count; input += count; bits >>>= count;
    } else {
      let offset, count, used;
      if (!(value & 3)) { offset = (value >>> 2) & 63; count = 3; used = 1; }
      else if (!(value & 2)) { offset = (value >>> 2) & 16383; count = 3; used = 2; }
      else if (!(value & 1)) { offset = (value >>> 6) & 1023; count = ((value >>> 2) & 15) + 3; used = 2; }
      else if ((value & 127) === 3) { offset = value >>> 15; count = ((value >>> 7) & 255) + 3; used = 4; }
      else { offset = (value >>> 7) & 131071; count = ((value >>> 2) & 31) + 2; used = 3; }
      if (offset > output || output + count > length) throw new Error('Invalid cache backreference');
      for (let i = 0; i < count; i++) out[output + i] = out[output + i - offset];
      output += count; input += used; bits >>>= 1;
    }
  }
  while (output < length) {
    if (bits === 1) { bits = 0x80000000; input += 4; }
    if (input >= src.length) throw new Error('Truncated cache');
    out[output++] = src[input++]; bits >>>= 1;
  }
  return stripHeader ? out.subarray(8) : out;
}

export function luaStrings(bytes) {
  if (bytes.subarray(0, 12).toString('hex') !== '1b4c75615100010404040800') {
    throw new Error('Unsupported Lua bytecode header');
  }
  let pos = 12;
  const strings = [];
  function u32() { const n = bytes.readUInt32LE(pos); pos += 4; return n; }
  function string(kind) {
    const offset = pos;
    const size = u32();
    if (size) {
      if (pos + size > bytes.length || bytes[pos + size - 1] !== 0) throw new Error(`Invalid Lua ${kind} string at ${offset}, size=${size}, end=${bytes[pos + size - 1]}`);
      const data = bytes.subarray(pos, pos + size - 1);
      let text = null;
      try { text = utf8.decode(data); } catch {}
      strings.push({ offset, end: pos + size, kind, text, data });
      pos += size;
    }
  }
  function prototype() {
    string('source');
    pos += 12;
    const instructions = u32();
    pos += instructions * 4;
    const constants = u32();
    for (let i = 0; i < constants; i++) {
      const type = bytes[pos++];
      if (type === 1) pos++;
      else if (type === 3) pos += 8;
      else if (type === 4) string('constant');
      else if (type !== 0) throw new Error(`Invalid Lua constant ${type}`);
    }
    const functions = u32();
    for (let i = 0; i < functions; i++) prototype();
    // PDE uses Lua 5.2-alpha chunks with a 5.1 header and explicit upvalue descriptors.
    const descriptors = u32();
    pos += descriptors * 2;
    const lines = u32();
    pos += lines * 4;
    const locals = u32();
    for (let i = 0; i < locals; i++) { string('local'); pos += 8; }
    const upvalues = u32();
    for (let i = 0; i < upvalues; i++) string('upvalue');
  }
  prototype();
  if (pos !== bytes.length) throw new Error(`Lua size mismatch ${pos}/${bytes.length}`);
  return strings;
}

export class PdeArchive {
  constructor(filename) {
    this.filename = filename;
    this.fd = fs.openSync(filename, 'r');
    this.size = fs.fstatSync(this.fd).size;
    this.key = Buffer.alloc(4096);
    let state = 0x42574954;
    for (let i = 0; i < this.key.length; i++) {
      state = Math.imul(state, 0x7fcf) >>> 0;
      this.key[i] = (state >>> 24) ^ (state >>> 16) ^ (state >>> 8) ^ state;
    }
  }
  close() { fs.closeSync(this.fd); }
  read(offset, length) {
    if (offset < 0 || offset + length > this.size) throw new Error('PDE read out of bounds');
    const result = Buffer.alloc(length);
    if (fs.readSync(this.fd, result, 0, length, offset) !== length) throw new Error('Short PDE read');
    for (let i = 0; i < length; i++) result[i] ^= this.key[(offset + i) % 4096];
    return result;
  }
  real(block) { return (block + Math.floor(block / 1024) + 1) * 4096; }
  next(block) { return this.read(Math.floor(block / 1024) * 0x401000 + (block % 1024) * 4, 4).readUInt32LE() & 0x7fffffff; }
  blocks(block, size) {
    const result = [];
    const seen = new Set();
    for (let remaining = size; remaining > 0; remaining -= 4096) {
      if (seen.has(block)) throw new Error('Cyclic VFS chain');
      seen.add(block);
      result.push(block);
      if (remaining > 4096) block = this.next(block);
    }
    return result;
  }
  data(entry) {
    return Buffer.concat(this.blocks(entry.block, entry.size).map((block, i) => this.read(this.real(block), Math.min(4096, entry.size - i * 4096))));
  }
  entries() {
    const result = [];
    const visited = new Set();
    const visit = (directory, prefix) => {
      if (visited.has(directory.block)) throw new Error('Repeated directory block');
      visited.add(directory.block);
      const data = this.data(directory);
      const blocks = this.blocks(directory.block, directory.size);
      for (let i = 0; i + 128 <= data.length; i += 128) {
        const type = data[i];
        if (type !== 1 && type !== 2) continue;
        const end = data.indexOf(0, i + 1);
        if (end < 0 || end >= i + 112) throw new Error('Invalid directory name');
        const name = data.subarray(i + 1, end).toString('utf8');
        const entry = { path: prefix + name, type, block: data.readUInt32LE(i + 120), size: data.readUInt32LE(i + 124), directoryOffset: this.real(blocks[Math.floor(i / 4096)]) + i % 4096 };
        result.push(entry);
        if (type === 2) visit(entry, entry.path + '/');
      }
    };
    visit({ block: 0, size: 4096 }, '');
    return result;
  }
}

