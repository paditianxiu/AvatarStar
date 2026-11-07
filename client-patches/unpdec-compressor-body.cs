// Replacement for ReCache.Compressor.Compress. Keep ReCache's match search and
// backreference encodings; fix control-word rollover, the literal-only tail,
// and enforce the native decoder's minimum match distance of three bytes.
public static byte[] Compress(byte[] data)
{
    ArgumentNullException.ThrowIfNull(data);
    using var output = new MemoryStream();
    int position = 0;
    while (position < data.Length)
    {
        uint control = 0x80000000;
        using var block = new MemoryStream();
        for (int bit = 0; bit < 31 && position < data.Length; bit++)
        {
            // The native decoder switches to literal copying for the last 10
            // bytes. A match must never consume any part of that final region.
            int length = 0;
            int offset = 0;
            if (position < data.Length - 10)
            {
                (offset, length) = FindBestMatch(data, position);
                length = Math.Min(length, data.Length - 10 - position);
            }
            if (length >= 3 && offset >= 3)
            {
                control |= 1u << bit;
                block.Write(EncodeBackReference(offset, length));
                position += length;
            }
            else
            {
                block.WriteByte(data[position++]);
            }
        }
        output.Write(BitConverter.GetBytes(control));
        block.WriteTo(output);
    }
    return output.ToArray();
}
