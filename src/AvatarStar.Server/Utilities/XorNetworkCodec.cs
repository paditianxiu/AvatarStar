namespace AvatarStar.Server.Utilities;

public static class XorNetworkCodec
{
    // Standard CRC32 (IEEE) table; matches client table at 0xDADEA8.
    private static readonly uint[] Crc32Table = CreateCrc32Table();

    public static uint SeedState(byte seed) => Crc32Table[seed];

    public static void DecodeInPlace(Span<byte> buffer, ref uint state)
    {
        for (var i = 0; i < buffer.Length; i++)
        {
            var key = (byte)state;
            var plain = (byte)(buffer[i] ^ key);
            buffer[i] = plain;
            state = Crc32Table[plain] ^ (state >> 8);
        }
    }

    public static void EncodeInPlace(Span<byte> buffer, ref uint state)
    {
        for (var i = 0; i < buffer.Length; i++)
        {
            var key = (byte)state;
            var plain = buffer[i];
            buffer[i] = (byte)(plain ^ key);
            state = Crc32Table[plain] ^ (state >> 8);
        }
    }

    private static uint[] CreateCrc32Table()
    {
        const uint poly = 0xEDB88320;
        var table = new uint[256];

        for (uint i = 0; i < table.Length; i++)
        {
            var crc = i;
            for (var j = 0; j < 8; j++)
            {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ poly : crc >> 1;
            }

            table[i] = crc;
        }

        return table;
    }
}
