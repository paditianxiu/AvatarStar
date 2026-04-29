using System.Security.Cryptography;

namespace AvatarStar.Server.Utilities;

/// <summary>
/// Client "DesNetworkEncoder" compatible codec (CFB-64 built on DES-ECB).
///
/// Behavior matches the client routines at:
/// - encrypt: sub_405640
/// - decrypt: sub_4057A0
///
/// Important quirk: for the final partial block (len % 8 != 0), the IV is NOT updated.
/// </summary>
public sealed class DesCfb64Codec : IDisposable
{
    private readonly DES _des;
    private ICryptoTransform _encryptor;

    private readonly byte[] _iv = new byte[8];
    private readonly byte[] _keystream = new byte[8];

    public DesCfb64Codec(ReadOnlySpan<byte> key)
    {
        _des = DES.Create();
        _des.Mode = CipherMode.ECB;
        _des.Padding = PaddingMode.None;
        _encryptor = _des.CreateEncryptor();
        SetKey(key);
        ResetIv();
    }

    public void ResetIv()
    {
        Array.Clear(_iv);
    }

    public void SetKey(ReadOnlySpan<byte> key)
    {
        if (key.Length != 8)
        {
            throw new ArgumentException("DES key must be exactly 8 bytes", nameof(key));
        }

        _des.Key = key.ToArray();

        _encryptor.Dispose();
        _encryptor = _des.CreateEncryptor();
    }

    /// <summary>Encrypts in-place: ciphertext = plaintext XOR DES(IV); IV = ciphertext (only after full blocks).</summary>
    public void EncryptInPlace(Span<byte> buffer)
    {
        Process(buffer, encrypt: true);
    }

    /// <summary>Decrypts in-place: plaintext = ciphertext XOR DES(IV); IV = ciphertext (only after full blocks).</summary>
    public void DecryptInPlace(Span<byte> buffer)
    {
        Process(buffer, encrypt: false);
    }

    private void Process(Span<byte> buffer, bool encrypt)
    {
        var offset = 0;
        while (offset + 8 <= buffer.Length)
        {
            // keystream = DES(IV)
            _encryptor.TransformBlock(_iv, 0, 8, _keystream, 0);

            // XOR with keystream.
            for (var i = 0; i < 8; i++)
            {
                buffer[offset + i] ^= _keystream[i];
            }

            // Update IV to ciphertext (for both encrypt/decrypt).
            // At this point buffer contains ciphertext if encrypt==true, otherwise plaintext;
            // but we need the original ciphertext on decrypt, so capture it before overwriting.
            if (!encrypt)
            {
                // On decrypt, IV is updated with the input ciphertext.
                // We need it from the pre-XOR bytes: ciphertext = plaintext XOR keystream.
                // Since buffer has plaintext now, reconstruct ciphertext for IV update.
                for (var i = 0; i < 8; i++)
                {
                    _iv[i] = (byte)(buffer[offset + i] ^ _keystream[i]);
                }
            }
            else
            {
                // On encrypt, buffer holds ciphertext already.
                buffer.Slice(offset, 8).CopyTo(_iv);
            }

            offset += 8;
        }

        // Tail: XOR with keystream generated from current IV, but DO NOT update IV.
        var tail = buffer.Length - offset;
        if (tail <= 0)
        {
            return;
        }

        _encryptor.TransformBlock(_iv, 0, 8, _keystream, 0);
        for (var i = 0; i < tail; i++)
        {
            buffer[offset + i] ^= _keystream[i];
        }
    }

    public void Dispose()
    {
        _encryptor.Dispose();
        _des.Dispose();
    }
}
