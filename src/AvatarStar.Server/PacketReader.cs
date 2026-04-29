using System.Buffers.Binary;
using System.Text;

namespace AvatarStar.Server;

public class PacketReader
{
    private readonly byte[] _data;
    private int _position;
    
    public PacketReader(byte[] data)
    {
        _data = data;
        _position = 0;
    }

    public int Remaining => _data.Length - _position;

    public ReadOnlySpan<byte> DataSpan => _data;

    public byte[] Data => _data;

    public ReadOnlySpan<byte> RemainingSpan => _data.AsSpan(_position);

    public bool TryPeekInt(out int value)
    {
        value = 0;
        if (_position + 4 > _data.Length) return false;
        value = BinaryPrimitives.ReadInt32LittleEndian(_data.AsSpan(_position));
        return true;
    }

    public bool TryReadByte(out byte value)
    {
        value = 0;
        if (_position + 1 > _data.Length) return false;
        value = _data[_position++];
        return true;
    }

    public bool TryReadInt(out int value)
    {
        value = 0;
        if (_position + 4 > _data.Length) return false;
        value = BinaryPrimitives.ReadInt32LittleEndian(_data.AsSpan(_position));
        _position += 4;
        return true;
    }

    public bool TryReadShort(out short value)
    {
        value = 0;
        if (_position + 2 > _data.Length) return false;
        value = BinaryPrimitives.ReadInt16LittleEndian(_data.AsSpan(_position));
        _position += 2;
        return true;
    }

    public bool TryReadLong(out long value)
    {
        value = 0;
        if (_position + 8 > _data.Length) return false;
        value = BinaryPrimitives.ReadInt64LittleEndian(_data.AsSpan(_position));
        _position += 8;
        return true;
    }

    public bool TryReadFixedBytes(int length, out byte[] value)
    {
        value = Array.Empty<byte>();
        if (length < 0) return false;
        if (_position + length > _data.Length) return false;
        value = _data.AsSpan(_position, length).ToArray();
        _position += length;
        return true;
    }

    public bool TryReadString(out string value, int maxLength = 16 * 1024)
    {
        value = string.Empty;
        if (!TryReadInt(out var length)) return false;
        if (length < 0 || length > maxLength) return false;
        if (_position + length > _data.Length) return false;
        value = Encoding.UTF8.GetString(_data, _position, length);
        _position += length;
        return true;
    }

    public bool TryReadVleUInt(out uint value)
    {
        value = 0;

        var shift = 0;
        var bytesRead = 0;

        while (true)
        {
            if (_position >= _data.Length)
            {
                return false;
            }

            var b = _data[_position++];
            bytesRead++;

            value |= (uint)(b & 0x7F) << shift;
            if ((b & 0x80) == 0)
            {
                return true;
            }

            shift += 7;
            if (shift > 28 || bytesRead >= 5)
            {
                return false;
            }
        }
    }

    public uint ReadVleUInt()
    {
        if (!TryReadVleUInt(out var value))
        {
            throw new ArgumentOutOfRangeException(nameof(value), "Invalid VLE integer");
        }

        return value;
    }

    public bool ReadBool()
    {
        return _data[_position++] == 1;
    }
    
    public byte ReadByte()
    {
        return _data[_position++];
    }
    
    public short ReadShort()
    {
        var value = BinaryPrimitives.ReadInt16LittleEndian(_data.AsSpan(_position));
        _position += 2;
        return value;
    }
    
    public int ReadInt()
    {
        var value = BinaryPrimitives.ReadInt32LittleEndian(_data.AsSpan(_position));
        _position += 4;
        return value;
    }
    
    public long ReadLong()
    {
        var value = BinaryPrimitives.ReadInt64LittleEndian(_data.AsSpan(_position));
        _position += 8;
        return value;
    }
    
    public string ReadString()
    {
        var length = ReadInt();
        var value = Encoding.UTF8.GetString(_data, _position, length);
        _position += length;
        return value;
    }

    public byte[] ReadBytes()
    {
        var length = ReadInt();
        var value = _data.AsSpan(_position, length).ToArray();
        _position += length;
        return value;
    }
}
