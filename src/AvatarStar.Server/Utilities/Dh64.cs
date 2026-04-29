using System.Buffers.Binary;
using System.Numerics;
using System.Security.Cryptography;

namespace AvatarStar.Server.Utilities;

/// <summary>
/// Diffie-Hellman-like 64-bit key agreement used by the newer client DesNetworkEncoder.
///
/// From RE (client_dump_SCY.exe):
/// - generator g = 0xCE0835F012503743
/// - modulus   p = 0xE09082D102CAC731
/// - private exponent bytes are 8 bytes, each in [1..255] (never zero)
/// - public/shared values are serialized as 8-byte big-endian.
/// </summary>
public static class Dh64
{
    public const ulong GeneratorG = 0xCE08_35F0_1250_3743UL;
    public const ulong ModulusP = 0xE090_82D1_02CA_C731UL;

    public static void GeneratePrivateExponent(Span<byte> priv8)
    {
        if (priv8.Length != 8)
        {
            throw new ArgumentException("Private exponent must be 8 bytes", nameof(priv8));
        }

        // Client uses rand()%255 + 1 for each byte.
        Span<byte> tmp = stackalloc byte[8];
        RandomNumberGenerator.Fill(tmp);
        for (var i = 0; i < 8; i++)
        {
            priv8[i] = (byte)((tmp[i] % 255) + 1);
        }
    }

    public static ulong ReadU64BigEndian(ReadOnlySpan<byte> be8)
    {
        if (be8.Length != 8)
        {
            throw new ArgumentException("Value must be 8 bytes", nameof(be8));
        }

        return BinaryPrimitives.ReadUInt64BigEndian(be8);
    }

    public static void WriteU64BigEndian(ulong value, Span<byte> be8)
    {
        if (be8.Length != 8)
        {
            throw new ArgumentException("Output must be 8 bytes", nameof(be8));
        }

        BinaryPrimitives.WriteUInt64BigEndian(be8, value);
    }

    public static ulong ComputePublic(ulong privExponent)
    {
        return ModPow(GeneratorG % ModulusP, privExponent, ModulusP);
    }

    public static ulong ComputeShared(ulong otherPublic, ulong privExponent)
    {
        return ModPow(otherPublic % ModulusP, privExponent, ModulusP);
    }

    private static ulong ModPow(ulong @base, ulong exponent, ulong modulus)
    {
        if (modulus == 0)
        {
            throw new ArgumentOutOfRangeException(nameof(modulus));
        }

        var result = 1UL;
        var factor = @base % modulus;
        var e = exponent;

        while (e != 0)
        {
            if ((e & 1) != 0)
            {
                result = (ulong)((BigInteger)result * factor % modulus);
            }

            e >>= 1;
            if (e != 0)
            {
                factor = (ulong)((BigInteger)factor * factor % modulus);
            }
        }

        return result;
    }
}

