using System.Buffers;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Collections.Generic;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Utilities;
using System.Globalization;
using Microsoft.Extensions.Options;
using AvatarStar.Server.Persistence;
using Serilog;

namespace AvatarStar.Server.Game;

internal partial class GameClient : Client, IDisconnectAwareClient
{
    private readonly IOptionsMonitor<SysAvatarPayloadConfig> _sysAvatarPayloadMonitor;
    private readonly PlayerStore _playerStore;
    private readonly PracticeRoomManager _practiceRoomManager;
    private readonly AccountRepository _accounts;

    private static readonly bool DumpPackets =
        (Environment.GetEnvironmentVariable("AS_GAME_DUMP_PACKETS") ?? "0").Equals("1", StringComparison.OrdinalIgnoreCase);

    private static readonly int DumpMaxBytes =
        int.TryParse(Environment.GetEnvironmentVariable("AS_GAME_DUMP_MAX_BYTES"), out var v) && v > 0 ? v : 512;

    private static readonly bool BroadcastPacket40RawBlob =
        (Environment.GetEnvironmentVariable("AS_BROADCAST_PACKET40_RAW_BLOB") ?? "0")
        .Equals("1", StringComparison.OrdinalIgnoreCase);

    private static void DumpPacket(string direction, System.Net.IPEndPoint remote, ReadOnlySpan<byte> data)
    {
        if (!DumpPackets) return;
        if (!Log.IsEnabled(Serilog.Events.LogEventLevel.Debug)) return;

        var packetId = data.Length > 0 ? data[0] : (byte)0;
        var preview = data.Length <= DumpMaxBytes ? data.ToArray() : data[..DumpMaxBytes].ToArray();
        Log.Debug("[{Dir}:{Remote}] packetId={PacketId} len={Len}\n{Hex}",
            direction, remote, packetId, data.Length, HexDump.Dump(preview));
    }

    private static string LuaEscape(string value)
    {
        if (value.Length == 0) return "\"\"";

        var sb = new StringBuilder(value.Length + 2);
        sb.Append('\"');
        foreach (var ch in value)
        {
            switch (ch)
            {
                case '\\':
                    sb.Append("\\\\");
                    break;
                case '\"':
                    sb.Append("\\\"");
                    break;
                case '\n':
                    sb.Append("\\n");
                    break;
                case '\r':
                    sb.Append("\\r");
                    break;
                case '\t':
                    sb.Append("\\t");
                    break;
                case '\0':
                    sb.Append("\\0");
                    break;
                default:
                    sb.Append(ch);
                    break;
            }
        }
        sb.Append('\"');
        return sb.ToString();
    }
    
    private ProtocolState _state;
    private CryptoMode _cryptoMode;

    // Newer client uses XORNetworkEncoder (CRC32-based stream XOR).
    // Client seeds (IDA sub_401010): encode=0x54425749, decode=0x57495442.
    // Server mirrors by direction: inbound(client->server)=0x54425749, outbound(server->client)=0x57495442.
    //
    // Handshake (IDA sub_910AB0 / sub_91A200):
    // - First C->S frame payload (len=9) is encrypted with initial inbound state (0x54425749) and decrypts to:
    //     [byte clientSeed][8 bytes clientNonce]
    //   After decrypting it, server must RESET inbound state to CRC32_TABLE[clientSeed].
    // - First S->C frame payload (len=9) must be encrypted with initial outbound state (0x57495442) and decrypts to:
    //     [byte serverSeed][8 bytes serverNonce]
    //   After sending it, server must RESET outbound state to CRC32_TABLE[serverSeed].
    private const uint XorInInitial = 0x54425749;
    private const uint XorOutInitial = 0x57495442;

    private uint _xorInState = XorInInitial;
    private uint _xorOutState = XorOutInitial;

    // After the XOR handshake, client switches to DesNetworkEncoder (DES-CFB64 over payload).
    // Session key is derived via a 64-bit DH-like exchange, then each packet is encrypted/decrypted
    // with IV reset to 0 (see client wrappers at 0x401320/0x401350).
    private static readonly byte[] DesHandshakeKey = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07];
    private readonly DesCfb64Codec _desHandshake = new(DesHandshakeKey);
    private readonly DesCfb64Codec _desIn = new(DesHandshakeKey);
    private readonly DesCfb64Codec _desOut = new(DesHandshakeKey);

    private long _activeRoleId;
    private long _activeAccountId = 1;
    private string _activeRoleExtra = string.Empty;
    private bool _lobbyRoomListReady;

    private readonly record struct LobbyLevelInfo(
        long Id,
        string Name,
        byte GameType,
        string ShowName,
        string Description,
        int Difficulty,
        int Group);

    private const string LobbyLevelInfoConfigFileName = "lobby_levelinfo.json";

    // Minimum LevelInfo list for lobby room/map UI:
    // StateLobby:GetLevelCount/GetLevelInfo are populated from packet 30 (sub_9155B0).
    // If this list is empty, the client cannot build its available level map.
    private static readonly LobbyLevelInfo[] DefaultLobbyLevels =
    [
        new(
            Id: 1,
            Name: "LEVEL1",
            GameType: 4, // kTeamDead
            ShowName: "id_datalist_Belfry_Square_level1",
            Description: "id_datalist_Belfry_Square_level1",
            Difficulty: 0,
            Group: 0),
    ];

    private static string? ResolveLobbyLevelInfoConfigPath()
    {
        var envPath = Environment.GetEnvironmentVariable("AS_LOBBY_LEVELINFO_PATH");
        if (!string.IsNullOrWhiteSpace(envPath) && File.Exists(envPath))
        {
            return envPath;
        }

        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Config", LobbyLevelInfoConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "Config", LobbyLevelInfoConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Config", LobbyLevelInfoConfigFileName),
        };

        foreach (var path in candidates)
        {
            if (File.Exists(path))
            {
                return path;
            }
        }

        return null;
    }

    private static bool TryExtractLevelId(string key, out long id)
    {
        var sb = new StringBuilder(key.Length);
        foreach (var ch in key)
        {
            if (ch is >= '0' and <= '9')
            {
                sb.Append(ch);
            }
        }

        if (sb.Length == 0)
        {
            id = 0;
            return false;
        }

        return long.TryParse(sb.ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out id);
    }

    private static IReadOnlyList<LobbyLevelInfo> GetConfiguredLobbyLevelsOrDefault()
    {
        try
        {
            using var db = new AvatarStarDbContext();
            var dbLevels = db.LobbyLevels
                .Where(x => x.Enabled == 1)
                .OrderBy(x => x.Id)
                .Select(x => new LobbyLevelInfo(
                    x.Id,
                    x.Name,
                    (byte)Math.Clamp(x.GameType, 0, byte.MaxValue),
                    x.ShowName,
                    x.Description,
                    x.Difficulty,
                    x.Group))
                .ToArray();
            if (dbLevels.Length > 0)
            {
                return dbLevels;
            }
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load lobby levels from database. Using JSON/default levels.");
        }

        var configPath = ResolveLobbyLevelInfoConfigPath();
        if (string.IsNullOrWhiteSpace(configPath))
        {
            return DefaultLobbyLevels;
        }

        try
        {
            var json = File.ReadAllText(configPath, Encoding.UTF8);
            var map = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
            if (map is null || map.Count == 0)
            {
                Log.Warning("Lobby level config is empty: {Path}. Using fallback levels.", configPath);
                return DefaultLobbyLevels;
            }

            var levels = new List<LobbyLevelInfo>(map.Count);
            foreach (var entry in map)
            {
                if (!TryExtractLevelId(entry.Key, out var levelId))
                {
                    Log.Warning("Lobby level config key has no numeric id and will be skipped: {Key}", entry.Key);
                    continue;
                }

                var textKey = string.IsNullOrWhiteSpace(entry.Value) ? entry.Key : entry.Value;
                levels.Add(new LobbyLevelInfo(
                    Id: levelId,
                    Name: entry.Key,
                    GameType: 4, // kTeamDead default; expand to per-level game_type when metadata is available
                    ShowName: textKey,
                    Description: textKey,
                    Difficulty: 0,
                    Group: 0));
            }

            if (levels.Count == 0)
            {
                Log.Warning("Lobby level config has no valid entries: {Path}. Using fallback levels.", configPath);
                return DefaultLobbyLevels;
            }

            return levels;
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load lobby level config from {Path}. Using fallback levels.", configPath);
            return DefaultLobbyLevels;
        }
    }

    internal string ResolveLobbyMapName(long levelId)
    {
        if (levelId == 0)
        {
            return "UI_common_Random_Map";
        }

        foreach (var level in GetConfiguredLobbyLevelsOrDefault())
        {
            if (level.Id == levelId)
            {
                return level.ShowName;
            }
        }

        return string.Empty;
    }

    internal string ResolveBattleLevelCode(long levelId, byte gameType)
    {
        if (levelId == 0)
        {
            return gameType switch
            {
                4 => "LEVEL17",
                _ => "LEVEL17"
            };
        }

        var levels = GetConfiguredLobbyLevelsOrDefault();
        if (levelId != 0)
        {
            foreach (var level in levels)
            {
                if (level.Id == levelId)
                {
                    return level.Name;
                }
            }
        }

        foreach (var level in levels)
        {
            if (level.Id != 0 && (gameType == 0 || level.GameType == gameType))
            {
                return level.Name;
            }
        }

        return "LEVEL17";
    }

    private void ResetLobbySessionContext()
    {
        _practiceRoomManager.UnregisterGameClient(_activeRoleId, this);
        _activeRoleId = 0;
        _activeRoleExtra = string.Empty;
        _lobbyRoomListReady = false;
    }

    private Task SendPacket51ForCurrentContext()
    {
        return SendPacket51LobbyRoomListChanged();
    }

    private static int GetIntArg(IReadOnlyDictionary<string, string> args, string key, int defaultValue = 0)
    {
        return args.TryGetValue(key, out var s) && int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out var v)
            ? v
            : defaultValue;
    }

    private PlayerStore.PlayerState GetActivePlayerStateOrDefault(int? requestedId = null)
    {
        if (requestedId is { } rid)
        {
            return _playerStore.GetOrCreate(rid);
        }

        if (_activeRoleId != 0)
        {
            return _playerStore.GetOrCreate((int)_activeRoleId);
        }

        // Default fallback player for lobby flows that assume `player` exists.
        _activeRoleId = 1;
        return _playerStore.GetOrCreate(1);
    }

    // Lobby dispatch mapping (IDA sub_91A200 -> byte_91AC98, state=5):
    //   30 -> sub_9155B0 (LevelInfo list used by GetLevelCount/GetLevelInfo)
    //   32 -> sub_9124E0 (reads int32 resultCode)
    //   51 -> sub_9195E0 (StateLobby RoomInfo list: roomUid + descriptor + int32 0 terminator)
    //
    // Connected/room states (byte_91AAA8, state=6/7) use a different packet family.
    // Client sub_910D10: receiving packet id=2 (no payload) forces stream state back to 4
    // so StateSelectCharacter:EnterLobby() can be called again.
    private async Task SendPacket2ReturnToSelectCharacter()
    {
        using var writer = new PacketWriter();
        writer.WriteByte(2);
        await SendAsync(writer);
    }

    // sub_9195E0 payload shape:
    // repeated until int32 roomUid == 0:
    //   int32 roomUid
    //   full RoomInfo fields in sub_5B91D0 order
    private async Task SendPacket51LobbyRoomListChanged()
    {
        var rooms = _practiceRoomManager.ListLobbyRooms();
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteLobbyRoomListChanged(writer, rooms);

        await SendAsync(writer);

        Log.Information(
            "PacketId=51 lobby room-info list sent: remote={Remote} count={Count} rooms={Rooms}",
            RemoteEndPoint,
            rooms.Count,
            string.Join("; ", rooms.Select(room =>
                $"{room.RoomUid}:state={room.RoomState},levelId={room.LevelId},gameType={room.GameType},players={room.CurrentClientNum}/{room.MaxClientNum},matching={room.Matching},canBeWatched={room.CanBeWatched},enterLimit={room.EnterLimit}")));
    }

    // sub_9155B0 payload shape:
    // [int32 levelCount]
    //   repeated levelCount:
    //     [int64 id][string name][byte gameType][string showName][string description][int32 difficulty][int32 group]
    private async Task SendPacket30LobbyLevelList(IReadOnlyList<LobbyLevelInfo>? levels = null)
    {
        levels ??= GetConfiguredLobbyLevelsOrDefault();

        using var writer = new PacketWriter();
        writer.WriteByte(30);
        writer.WriteInt(levels.Count);

        foreach (var level in levels)
        {
            writer.WriteLong(level.Id);
            writer.WriteString(level.Name);
            writer.WriteByte(level.GameType);
            writer.WriteString(level.ShowName);
            writer.WriteString(level.Description);
            writer.WriteInt(level.Difficulty);
            writer.WriteInt(level.Group);
        }

        await SendAsync(writer);
    }

    // sub_9124E0 reads int32 and forwards to upper-layer result handling.
    private async Task SendPacket32Result(int resultCode = 0)
    {
        using var writer = new PacketWriter();
        writer.WriteByte(32);
        writer.WriteInt(resultCode);
        await SendAsync(writer);
    }

    private async Task SendPacket36RoomListRefreshResult(byte result = 0)
    {
        using var writer = new PacketWriter();
        writer.WriteByte(AvatarStarClientProtocol.LobbyRoomListRefreshResult);
        writer.WriteByte(result);
        writer.WriteString(string.Empty);
        await SendAsync(writer);
    }

    public override Task SendRoomListChangedNotificationAsync()
    {
        return _state == ProtocolState.Connected && _lobbyRoomListReady
            ? SendPacket51ForCurrentContext()
            : Task.CompletedTask;
    }

    public GameClient(
        ClientHandler clientHandler,
        Socket socket,
        IOptionsMonitor<SysAvatarPayloadConfig> sysAvatarPayloadMonitor,
        PlayerStore playerStore,
        PracticeRoomManager practiceRoomManager,
        AccountRepository accounts) : base(clientHandler, socket)
    {
        _sysAvatarPayloadMonitor = sysAvatarPayloadMonitor;
        _playerStore = playerStore;
        _practiceRoomManager = practiceRoomManager;
        _accounts = accounts;
        _state = ProtocolState.AwaitHandshake;
        _cryptoMode = CryptoMode.XorHandshake;
    }

    protected override async Task HandleAsync(PacketReader reader)
    {
        // Decrypt in-place (payload only; length prefix already removed by ClientBuffer).
        switch (_cryptoMode)
        {
            case CryptoMode.XorHandshake:
                XorNetworkCodec.DecodeInPlace(reader.Data, ref _xorInState);
                break;
            case CryptoMode.DesSession:
                // New protocol resets IV per packet (CFB within a single packet only).
                _desIn.ResetIv();
                _desIn.DecryptInPlace(reader.Data);
                break;
            default:
                throw new InvalidOperationException($"Unknown crypto mode {_cryptoMode}");
        }

        DumpPacket("C->S", RemoteEndPoint, reader.DataSpan);

        switch (_state)
        {
            case ProtocolState.AwaitHandshake:
            {
                await HandleHandshake(reader);
                break;
            }

            case ProtocolState.AwaitLogin:
            {
                await HandleLogin(reader);
                break;
            }

            case ProtocolState.Connected:
            {
                await HandleConnected(reader);
                break;
            }

            default:
            {
                Log.Error("Unhandled protocol state {State}", _state);
                break;
            }
        }
        
        // Check for remaining data
        if (reader.Remaining > 0)
        {
            Log.Warning("Packet has {Remaining} bytes remaining", reader.Remaining);
        }
    }

    private async Task HandleHandshake(PacketReader reader)
    {
        Log.Debug("Handling handshake packet with payload length {PacketLen}", reader.Remaining);

        // After decryption with the *initial* inbound state (0x54425749), handshake plaintext is:
        //   [byte clientSeed][8 bytes clientNonce]
        if (reader.Remaining != 9)
        {
            Log.Warning("Unexpected handshake payload length {Len} (expected 9)", reader.Remaining);
            return;
        }

        if (!reader.TryReadByte(out var clientSeed) || !reader.TryReadFixedBytes(8, out var clientNonce))
        {
            Log.Warning("Failed to parse handshake payload");
            return;
        }

        Log.Debug("Handshake: clientSeed=0x{Seed:X2} clientNonce={NonceHex}", clientSeed, Convert.ToHexString(clientNonce));

        // IMPORTANT: reset inbound state to CRC32_TABLE[clientSeed] (client does sub_401150 after sending).
        _xorInState = XorNetworkCodec.SeedState(clientSeed);

        // ClientNonce is produced by DesNetworkEncoder using:
        // - fixed handshake key: 00 01 02 03 04 05 06 07
        // - IV = 0
        // Decrypting it yields the client's DH public A (8 bytes, big-endian).
        _desHandshake.ResetIv();
        _desHandshake.DecryptInPlace(clientNonce);
        Log.Debug("Handshake: clientPublic(A)={AHex}", Convert.ToHexString(clientNonce));

        // Server DH: generate private b and derive:
        // - public B = g^b mod p
        // - shared S = A^b mod p
        var serverPrivBytes = new byte[8];
        Dh64.GeneratePrivateExponent(serverPrivBytes);
        var serverPriv = Dh64.ReadU64BigEndian(serverPrivBytes);

        var clientPublic = Dh64.ReadU64BigEndian(clientNonce);
        var serverPublic = Dh64.ComputePublic(serverPriv);
        var sharedSecret = Dh64.ComputeShared(clientPublic, serverPriv);

        var serverPublicBytes = new byte[8];
        var sharedSecretBytes = new byte[8];
        Dh64.WriteU64BigEndian(serverPublic, serverPublicBytes);
        Dh64.WriteU64BigEndian(sharedSecret, sharedSecretBytes);

        Log.Debug("Handshake: serverPublic(B)={BHex}", Convert.ToHexString(serverPublicBytes));
        Log.Debug("Handshake: sharedSecret(S)={SHex}", Convert.ToHexString(sharedSecretBytes));

        // Configure session DES codecs with derived key (S). Client uses S directly as DES key bytes.
        _desIn.SetKey(sharedSecretBytes);
        _desOut.SetKey(sharedSecretBytes);

        // Build and send server handshake response (encrypted with initial outbound state).
        var serverSeed = RandomNumberGenerator.GetBytes(1)[0];
        var serverNonceCipher = serverPublicBytes.ToArray();

        // Encrypt B using the fixed handshake key and IV=0.
        _desHandshake.ResetIv();
        _desHandshake.EncryptInPlace(serverNonceCipher);

        using var packet = new PacketWriter();
        packet.WriteByte(serverSeed);
        packet.WriteRaw(serverNonceCipher);

        // Encrypt handshake using the initial outbound state, then reset to CRC32_TABLE[serverSeed].
        _xorOutState = XorOutInitial;
        await SendAsync(packet);
        _xorOutState = XorNetworkCodec.SeedState(serverSeed);

        Log.Debug("Handshake: sent serverSeed=0x{Seed:X2} serverNonce(ciphertext)={NonceHex}", serverSeed, Convert.ToHexString(serverNonceCipher));

        // Switch to DES for subsequent payloads (client does this after receiving server handshake).
        _cryptoMode = CryptoMode.DesSession;
        _state = ProtocolState.AwaitLogin;
    }

    private async Task HandleLogin(PacketReader reader)
    {
        Log.Debug("Handling login packet with payload length {PacketLen}", reader.Remaining);

        // Client login request (Conn_ProcessIncoming_StateMachine @ 0x91A200):
        //   [u32 len][version utf8][byte flag]
        //   if flag==1: [u32 len][token utf8]
        //   if flag==0: [u32 len][username utf8][u32 len][password utf8]
        //
        // Example (token):
        //   0B 00 00 00 "1.4.0.65795" 01 09 00 00 00 "AuthToken"
        if (!reader.TryReadString(out var version) || !reader.TryReadByte(out var flag))
        {
            Log.Warning("Login packet not in (string,byte,...) format; treating payload as auth blob (len={Len})", reader.RemainingSpan.Length);
            Log.Debug("Login auth blob (hex): {Hex}", HexDump.Dump(reader.RemainingSpan.ToArray()));

            using var loginResponse = new PacketWriter();
            loginResponse.WriteInt(1);         // loginResult (non-zero = success)
            loginResponse.WriteLong(1);        // session/uid (must be non-zero)
            loginResponse.WriteString("OK");   // message
            await SendAsync(loginResponse);

            _state = ProtocolState.Connected;
            return;
        }

        string? token = null;
        string? username = null;
        string? password = null;

        if (flag == 1)
        {
            if (!reader.TryReadString(out token))
            {
                Log.Warning("Login packet flag=1 but token missing; treating remainder as auth blob (len={Len})", reader.RemainingSpan.Length);
                Log.Debug("Login auth blob (hex): {Hex}", HexDump.Dump(reader.RemainingSpan.ToArray()));
            }
        }
        else
        {
            if (!reader.TryReadString(out username) || !reader.TryReadString(out password))
            {
                Log.Warning("Login packet flag={Flag} but username/password missing; treating remainder as auth blob (len={Len})", flag, reader.RemainingSpan.Length);
                Log.Debug("Login auth blob (hex): {Hex}", HexDump.Dump(reader.RemainingSpan.ToArray()));
            }
        }

        if (token is not null)
        {
            _activeAccountId = _accounts.ValidateToken(token);
            _playerStore.SetCurrentAccount(_activeAccountId);
            Log.Information("Login: version={Version} flag={Flag} tokenLen={TokenLen}", version, flag, token.Length);
        }
        else
        {
            _activeAccountId = 1;
            _playerStore.SetCurrentAccount(_activeAccountId);
            Log.Information("Login: version={Version} flag={Flag} userLen={UserLen}", version, flag, username?.Length ?? 0);
        }

        using var response = new PacketWriter();
        response.WriteInt(1);         // loginResult (non-zero = success)
        response.WriteLong(1);        // session/uid (must be non-zero)
        response.WriteString("OK");   // message
        await SendAsync(response);

        _state = ProtocolState.Connected;
    }

    private async Task HandleConnected(PacketReader reader)
    {
        Log.Debug("Handling connected packet with payload length {PacketLen}", reader.Remaining);

        var first = reader.RemainingSpan.Length > 0 ? reader.RemainingSpan[0] : (byte)0;

        // Newer client protocol uses VLE/varint-coded message ids (first byte often has MSB=1).
        // Older protocol used a single-byte packet id.
        uint packetId = first >= 0x80 ? reader.ReadVleUInt() : reader.ReadByte();

        switch (packetId)
        {
            // LogoutCharacter (client wrapper sub_910160): packet id 2, no payload.
            // Must reply packet id 2 so client executes sub_910D10 and returns to state=4.
            case 2:
            {
                Log.Information("PacketId=2 LogoutCharacter");
                ResetLobbySessionContext();
                await SendPacket2ReturnToSelectCharacter();
                Log.Information("PacketId=2 response sent: ReturnToSelectCharacter (lobby context reset)");
                break;
            }
            // Client-side lobby packet15 handler (sub_913F40) is a generic downlink result dispatcher
            // that only reads u32 resultCode. Echoing an incoming opcode15 back as "15Ack" is risky.
            // Treat incoming opcode15 as a transition/refresh hint and answer with stateful data instead.
            case 15:
            {
                byte arg = 0;
                var hasArg = reader.TryReadByte(out arg);
                Log.Information("PacketId=15 request hasArg={HasArg} arg={Arg} remaining={Remaining}", hasArg, arg, reader.Remaining);

                if (!hasArg || arg == 0)
                {
                    await SendPacket30LobbyLevelList();
                    _lobbyRoomListReady = true;
                    Log.Information("PacketId=15 arg=0 response sent: 30LobbyLevelList");
                }

                break;
            }
            // EnterLobby request (Client.StateSelectCharacter:EnterLobby)
            // Layout (client send @ 0x910100):
            //   byte 1
            //   int64 roleId
            //   string userIdOrExtra (often empty when launched without login launcher)
            //
            // Response expected by client (handled by sub_9150F0): a fixed sequence of
            // primitives; we provide minimal defaults to allow progressing into lobby/tutorial.
            case 1:
            {
                if (!reader.TryReadLong(out var roleId) || !reader.TryReadString(out var extra))
                {
                    Log.Warning("PacketId=1 EnterLobby parse failed (remaining={Remaining})", reader.Remaining);
                    break;
                }

                Log.Information("EnterLobby: remote={Remote} roleId={RoleId} extraLen={ExtraLen}", RemoteEndPoint, roleId, extra.Length);
                _practiceRoomManager.UnregisterGameClient(_activeRoleId, this);
                _activeRoleId = roleId;
                _activeRoleExtra = extra;
                _lobbyRoomListReady = false;
                _practiceRoomManager.RegisterGameClient(roleId, this);

                using var writer = new PacketWriter();
                writer.WriteByte(1);          // packetId
                writer.WriteLong(roleId);     // echoes roleId (u64)
                writer.WriteString(extra);    // string field (can be empty)
                writer.WriteInt(0);           // int32
                writer.WriteByte(0);          // byte
                writer.WriteByte(0);          // byte
                writer.WriteInt(0);           // int32
                writer.WriteByte(0);          // byte
                writer.WriteString("");       // string
                writer.WriteInt(1);           // int32 (treat as "newbie/tutorial" hint)

                await SendAsync(writer);
                break;
            }
            // Client sends a config blob (often key bindings) as UTF-8 script text.
            case 31:
            {
                var payload = reader.RemainingSpan.ToArray();
                _ = reader.TryReadFixedBytes(payload.Length, out _);
                var preview = Encoding.UTF8.GetString(payload, 0, Math.Min(payload.Length, 256)).Replace("\0", "\\0");
                Log.Debug("PacketId=31 clientConfig len={Len} preview={Preview}", payload.Length, preview);
                break;
            }
            case 3:
            {
                await HandlePacket3RequestChannelAsync(reader);
                break;
            }
            case 38:
            {
                await HandlePacket38CreateRoomAsync(reader);
                break;
            }
            case 36:
            {
                const byte result = 0;
                if (!_lobbyRoomListReady)
                {
                    await SendPacket30LobbyLevelList();
                    _lobbyRoomListReady = true;
                    Log.Information("PacketId=36 preloaded 30LobbyLevelList before room-list refresh");
                }

                await SendPacket36RoomListRefreshResult(result);
                await SendPacket51ForCurrentContext();
                Log.Information("PacketId=36 room-list refresh response sent: result={Result}", result);
                break;
            }
            // Client writer @ 0x910270: byte 40, int32 payload length, raw bytes.
            // Do not decode the blob as VLE integers; the first "int" in old logs was just the length.
            case 40:
            {
                await HandlePacket40RawBlobAsync(reader);
                break;
            }
            // rpc call?
            case 0:
            {
                await HandleRpcCall(reader, packetId);
                break;
            }
            default:
            {
                // For unknown packets, try decoding the remaining payload as a sequence of VLE integers to aid RE.
                var ints = new List<uint>();
                while (reader.Remaining > 0)
                {
                    var posBefore = reader.Remaining;
                    if (!reader.TryReadVleUInt(out var v))
                    {
                        break;
                    }

                    ints.Add(v);

                    // Safety: ensure progress.
                    if (reader.Remaining == posBefore)
                    {
                        break;
                    }
                }

                Log.Warning("Unhandled packetId={PacketId} (vleInts={IntsCount}) ints={Ints}", packetId, ints.Count, ints);
                break;
            }
        }
    }

    private async Task HandlePacket40RawBlobAsync(PacketReader reader)
    {
        var rawFrame = reader.RemainingSpan.ToArray();
        if (!reader.TryReadInt(out var payloadLength))
        {
            Log.Warning(
                "PacketId=40 raw blob malformed: missing length remaining={Remaining} hex={Hex}",
                rawFrame.Length,
                HexDump.Dump(rawFrame, 32).TrimEnd());
            return;
        }

        if (payloadLength < 0 || payloadLength > reader.Remaining)
        {
            Log.Warning(
                "PacketId=40 raw blob malformed: length={Length} remaining={Remaining} frameHex={Hex}",
                payloadLength,
                reader.Remaining,
                HexDump.Dump(rawFrame, 32).TrimEnd());
            return;
        }

        if (!reader.TryReadFixedBytes(payloadLength, out var payload))
        {
            Log.Warning(
                "PacketId=40 raw blob truncated: length={Length} remaining={Remaining}",
                payloadLength,
                reader.Remaining);
            return;
        }

        var trailingBytes = reader.Remaining;
        Log.Information(
            "PacketId=40 raw blob <- len={Length} trailingBytes={TrailingBytes} hex={Hex}",
            payload.Length,
            trailingBytes,
            HexDump.Dump(payload, 32).TrimEnd());

        var knifeRearmCount = await _practiceRoomManager.SendKnifeRearmForLobbyRawBlobAsync(
            _activeRoleId,
            "packet40-raw-blob");
        var broadcastCount = BroadcastPacket40RawBlob
            ? await _practiceRoomManager.BroadcastLobbyRawBlobAsync(
                _activeRoleId,
                payload,
                "packet40-raw-blob")
            : 0;
        if (knifeRearmCount > 0)
        {
            Log.Information(
                "PacketId=40 raw blob triggered knife rearm: roleId={RoleId} itemCount={ItemCount}",
                _activeRoleId,
                knifeRearmCount);
        }

        if (broadcastCount > 0)
        {
            Log.Information(
                "PacketId=40 raw blob broadcast: roleId={RoleId} payloadBytes={PayloadBytes} broadcastCount={BroadcastCount}",
                _activeRoleId,
                payload.Length,
                broadcastCount);
        }
    }

    internal async Task SendPacket40RawBlobAsync(byte[] payload, string trigger)
    {
        using var writer = new PacketWriter();
        writer.WriteByte(40);
        writer.WriteInt(payload.Length);
        writer.WriteRaw(payload);

        Log.Verbose(
            "PacketId=40 raw blob -> {Remote}: len={Length} trigger={Trigger}",
            RemoteEndPoint,
            payload.Length,
            trigger);
        await SendAsync(writer);
    }

    public void OnClientDisconnected()
    {
        _practiceRoomManager.UnregisterGameClient(_activeRoleId, this);
    }

    protected override ClientBuffer CreateBuffer()
    {
        return new GameClientBuffer();
    }

    protected override async Task SendAsync(ArraySegment<byte> data)
    {
        const int MaxLengthSize = 3;

        DumpPacket("S->C", RemoteEndPoint, data.AsSpan());
        
        var bufferLen = data.Count + MaxLengthSize;
        var buffer = ArrayPool<byte>.Shared.Rent(bufferLen);
        
        try
        {
            // Write packet length.
            var packetLengthSize = VLE.Encode(data.Count, buffer.AsSpan());
            if (packetLengthSize > MaxLengthSize)
            {
                throw new InvalidOperationException("Packet length is too large");
            }
            
            var bufferLenActual = packetLengthSize + data.Count;
            
            // Write payload.
            data.CopyTo(new ArraySegment<byte>(buffer, packetLengthSize, data.Count));

            // Encrypt payload in-place.
            switch (_cryptoMode)
            {
                case CryptoMode.XorHandshake:
                    XorNetworkCodec.EncodeInPlace(buffer.AsSpan(packetLengthSize, data.Count), ref _xorOutState);
                    break;
                case CryptoMode.DesSession:
                    // New protocol resets IV per packet (CFB within a single packet only).
                    _desOut.ResetIv();
                    _desOut.EncryptInPlace(buffer.AsSpan(packetLengthSize, data.Count));
                    break;
                default:
                    throw new InvalidOperationException($"Unknown crypto mode {_cryptoMode}");
            }
            
            await base.SendAsync(new ArraySegment<byte>(buffer, 0, bufferLenActual));
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(buffer);
        }
    }

    private enum ProtocolState
    {
        AwaitHandshake = 0,
        AwaitLogin = 1,
        Connected = 2
    }

    private enum CryptoMode
    {
        XorHandshake = 0,
        DesSession = 1
    }
}
