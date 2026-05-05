using System.Buffers;
using System.Buffers.Binary;
using System.Net.Sockets;
using AvatarStar.Server.Database;
using AvatarStar.Server.Utilities;
using MySqlConnector;
using Serilog;

namespace AvatarStar.Server.Login;

public class LoginClient : Client
{
    private static readonly bool DumpPackets =
        (Environment.GetEnvironmentVariable("AS_LOGIN_DUMP_PACKETS") ?? "0").Equals("1", StringComparison.OrdinalIgnoreCase);

    private static readonly int DumpMaxBytes =
        int.TryParse(Environment.GetEnvironmentVariable("AS_LOGIN_DUMP_MAX_BYTES"), out var v) && v > 0 ? v : 512;

    private static void DumpPacket(string direction, System.Net.IPEndPoint remote, ReadOnlySpan<byte> data)
    {
        if (!DumpPackets) return;
        if (!Log.IsEnabled(Serilog.Events.LogEventLevel.Debug)) return;

        var packetId = data.Length > 0 ? data[0] : (byte)0;
        var preview = data.Length <= DumpMaxBytes ? data.ToArray() : data[..DumpMaxBytes].ToArray();
        Log.Debug("[{Dir}:{Remote}] packetId={PacketId} len={Len}\n{Hex}",
            direction, remote, packetId, data.Length, HexDump.Dump(preview));
    }

    private static readonly AccountRepository Accounts = new();

    public LoginClient(ClientHandler clientHandler, Socket socket) : base(clientHandler, socket)
    {
    }

    protected override async Task HandleAsync(PacketReader reader)
    {
        DumpPacket("C->S", RemoteEndPoint, reader.DataSpan);

        var packetId = reader.ReadByte();

        Log.Debug("Handling packet {PacketId} with payload length {PacketLen}", packetId, reader.Remaining);

        switch (packetId)
        {
            case 0:
            {
                var pUnknown = reader.ReadShort();

                Log.Debug("- Unknown {Unknown}", pUnknown);
                break;
            }

            // Authentication
            case 3:
            {
                var pUsername = reader.ReadString();
                var pPassword = reader.ReadString();

                Log.Debug("- Username {Username}", pUsername);
                Log.Debug("- Password {Password}", pPassword);

                if (reader.ReadBool())
                {
                    Log.Debug("- Verification1 0x{Verify1}", reader.ReadBytes());
                    Log.Debug("- Verification2 {Verify2}", reader.ReadString());
                }

                if (reader.ReadBool())
                {
                    Log.Debug("- Unknown {UkInt}", reader.ReadInt());
                    Log.Debug("- Unknown {UkShort}", reader.ReadShort());
                }

                await HandleAccountLoginAsync(pUsername, pPassword);
                break;
            }

            // Load server list ?
            case 4:
            {
                var pUnknown = reader.ReadByte();

                Log.Debug("- Unknown {Unknown}", pUnknown);

                await WritePacket4();
                break;
            }

            // Register account and return token.
            case 5:
            {
                var pUsername = reader.ReadString();
                var pPassword = reader.ReadString();

                Log.Debug("- Register Username {Username}", pUsername);

                await HandleAccountRegisterAsync(pUsername, pPassword);
                break;
            }
        }

        // Check for remaining data
        if (reader.Remaining > 0)
        {
            Log.Warning("Packet {PacketId} has {Remaining} bytes remaining", packetId, reader.Remaining);
        }
    }

    private async Task HandleAccountLoginAsync(string username, string password)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            await WritePacket3(ServerErrorCode.InvalidUserId, null);
            return;
        }

        if (string.IsNullOrEmpty(password))
        {
            await WritePacket3(ServerErrorCode.PasswordError, null);
            return;
        }

        try
        {
            var result = await Accounts.LoginAsync(username, password);
            await WritePacket3(
                result.Success ? ServerErrorCode.Success : ServerErrorCode.PasswordError,
                result.Token);
        }
        catch (Exception ex) when (IsDatabaseException(ex))
        {
            Log.Error(ex, "Account login failed because database is unavailable");
            await WritePacket3(ServerErrorCode.SystemError, null);
        }
    }

    private async Task HandleAccountRegisterAsync(string username, string password)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            await WritePacket3(ServerErrorCode.InvalidUserId, null);
            return;
        }

        if (string.IsNullOrEmpty(password))
        {
            await WritePacket3(ServerErrorCode.PasswordError, null);
            return;
        }

        try
        {
            var result = await Accounts.RegisterAsync(username, password);
            await WritePacket3(
                result.Created ? ServerErrorCode.Success : ServerErrorCode.AccountLocked,
                result.Token);
        }
        catch (Exception ex) when (IsDatabaseException(ex))
        {
            Log.Error(ex, "Account registration failed because database is unavailable");
            await WritePacket3(ServerErrorCode.SystemError, null);
        }
    }

    private static bool IsDatabaseException(Exception ex)
    {
        return ex is MySqlException or InvalidOperationException;
    }

    protected override ClientBuffer CreateBuffer()
    {
        return new LoginClientBuffer();
    }

    protected override Task SendAsync(ArraySegment<byte> data)
    {
        DumpPacket("S->C", RemoteEndPoint, data.AsSpan());

        var bufferLen = data.Count + sizeof(short);
        var buffer = ArrayPool<byte>.Shared.Rent(bufferLen);

        try
        {
            // Write packet length.
            BinaryPrimitives.WriteInt16LittleEndian(buffer, (short)bufferLen);

            // Write payload.
            data.CopyTo(new ArraySegment<byte>(buffer, 2, data.Count));

            return base.SendAsync(new ArraySegment<byte>(buffer, 0, bufferLen));
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(buffer);
        }
    }

    private async Task WritePacket0(ServerErrorCode errorCode)
    {
        using var writer = new PacketWriter();

        writer.WriteByte(0);
        writer.WriteInt((int)errorCode);

        await SendAsync(writer);
    }

    /// <summary>
    ///     Handler 0x446500
    ///     Calls SendMessageW(.., 1339, this->field_2C, this->field_3)
    /// </summary>
    private async Task WritePacket1()
    {
        using var writer = new PacketWriter();

        writer.WriteByte(1);
        writer.WriteByte(1);
        writer.WriteString("Test"); // Size >= 0 and < 260
        writer.WriteBool(false);
        writer.WriteBool(false);

        await SendAsync(writer);
    }

    /// <summary>
    ///     Handler 0x4466B0
    ///     Calls SendMessageW(.., 1340, 0, LPARAM)
    ///     Sets
    ///     - serverStringOne
    ///     - serverDataOne
    /// </summary>
    private async Task WritePacket2()
    {
        using var writer = new PacketWriter();

        writer.WriteByte(2);
        // SendMessageW LPARAM
        writer.WriteByte(1);
        // serverStringOne
        writer.WriteString("Test");
        // serverDataOne
        writer.WriteBytes([0x01, 0x01, 0x01, 0x01]);

        await SendAsync(writer);
    }

    /// <summary>
    ///     Handler 0x446790
    ///     Calls SendMessageW(.., 1341, wParam, lParam)
    ///     - serverStringOne
    ///     - serverStringTwo
    ///     - serverDataOne (optional)
    /// </summary>
    private async Task WritePacket3(ServerErrorCode errorCode, string? authToken)
    {
        using var writer = new PacketWriter();

        writer.WriteByte(3);
        // WPARAM (ErrorCode)
        writer.WriteInt((int)errorCode);

        // Data below only when error code is success.
        if (errorCode == ServerErrorCode.Success)
        {
            // 1 = Verification ?
            // 4 = ?
            // 5 = ?
            // writer.WriteByte(5); // 1, 4 or 5
            // writer.WriteString("Test");
            // writer.WriteBytes([0x01, 0x01, 0x01, 0x01]);

            // 0 = Success
            writer.WriteByte(0);
            writer.WriteString(authToken ?? "Default");
        }

        await SendAsync(writer);
    }

    /// <summary>
    ///     Handler 0x446900
    /// </summary>
    private async Task WritePacket4()
    {
        using var writer = new PacketWriter();

        writer.WriteByte(4);

        for (var i = 0; i < ServerManager.Servers.Length; i++)
        {
            var category = ServerManager.Servers[i];

            writer.WriteByte(category.Id);
            writer.WriteString(category.Name); // Max 64

            for (var j = 0; j < category.Servers.Length; j++)
            {
                var server = category.Servers[j];

                writer.WriteByte(server.Id);
                writer.WriteString(server.Name); // Max 100
                writer.WriteString(server.Ip); // ServerIp
                writer.WriteInt(server.Port); // ServerPort
                writer.WriteByte(server.Status); // >0 = Idle, >50 = Heavy, >80 = Full, 255 Maintain

                // True if there are more servers in the category
                writer.WriteBool(j + 1 < category.Servers.Length);
            }

            // True if there are more categories
            writer.WriteBool(i + 1 < ServerManager.Servers.Length);
        }

        writer.WriteBool(false);

        await SendAsync(writer);
    }

    // Packet 255: Empty packet
}
