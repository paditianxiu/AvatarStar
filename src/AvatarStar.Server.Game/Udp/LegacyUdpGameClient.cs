using AvatarStar.Server.Game.Config;
using Microsoft.Extensions.Options;
using Serilog;

namespace AvatarStar.Server.Game.Udp;

internal sealed class LegacyUdpGameClient
{
    private readonly UdpReliableSession _session;
    private readonly IOptionsMonitor<SysAvatarPayloadConfig> _sysAvatarPayloadMonitor;

    private int _lobbyState;

    public LegacyUdpGameClient(UdpReliableSession session, IOptionsMonitor<SysAvatarPayloadConfig> sysAvatarPayloadMonitor)
    {
        _session = session;
        _sysAvatarPayloadMonitor = sysAvatarPayloadMonitor;
        _lobbyState = 1;
    }

    public async Task HandleAsync(PacketReader reader)
    {
        switch (_lobbyState)
        {
            case 1:
                await HandleStateConnecting(reader);
                break;
            case 2:
                await HandleStateAvatarSelection(reader);
                break;
            default:
                Log.Error("[UDP:{Remote}] Unhandled lobby state {LobbyState}", _session.RemoteEndPoint, _lobbyState);
                break;
        }

        if (reader.Remaining > 0)
        {
            Log.Warning("[UDP:{Remote}] Packet has {Remaining} bytes remaining", _session.RemoteEndPoint, reader.Remaining);
        }
    }

    private async Task HandleStateConnecting(PacketReader reader)
    {
        // Legacy client (old protocol) does NOT include the (type,seq,ack) triple inside the VLE-framed payload.
        // Transport-level reliable UDP already handles that.
        //
        // Observed legacy initial payload is a small binary blob. For now we follow the existing server's "fallback" path:
        //   int clientVersion, int authData, byte hasToken
        //
        // This allows us to log and keep progressing to avatar selection.
        var clientVersionInt = reader.ReadInt();
        var authData = reader.ReadInt();
        var hasToken = reader.ReadByte();

        Log.Debug("[UDP:{Remote}] Legacy connect: clientVersion={Version}, authData={Auth}, hasToken={HasToken}",
            _session.RemoteEndPoint, clientVersionInt, authData, hasToken);

        using var packet = new PacketWriter();
        packet.WriteInt(1);
        packet.WriteInt(1);
        packet.WriteInt(1);
        packet.WriteString("Aeon");

        await SendAsync(packet);
        _lobbyState = 2;
    }

    private async Task HandleStateAvatarSelection(PacketReader reader)
    {
        Log.Debug("[UDP:{Remote}] Avatar selection packet len={Len}", _session.RemoteEndPoint, reader.Remaining);

        var packetId = reader.ReadByte();
        switch (packetId)
        {
            case 2:
            {
                // Client LogoutCharacter flow expects packet id=2 with no payload to return to character-select state.
                Log.Information("[UDP:{Remote}] PacketId=2 LogoutCharacter", _session.RemoteEndPoint);
                using var writer = new PacketWriter();
                writer.WriteByte(2);
                await SendAsync(writer);
                Log.Information("[UDP:{Remote}] PacketId=2 response sent: ReturnToSelectCharacter", _session.RemoteEndPoint);
                break;
            }
            case 0:
            {
                var rpcId = reader.ReadInt();
                var rpcName = reader.ReadString();
                var rpcArgs = new Dictionary<string, string>();

                Log.Debug("[UDP:{Remote}] RPC: id={RpcId}, name={RpcName}, remaining={Remaining}",
                    _session.RemoteEndPoint, rpcId, rpcName, reader.Remaining);

                while (reader.Remaining > 0)
                {
                    var key = reader.ReadString();
                    if (key == string.Empty)
                    {
                        break;
                    }

                    var value = reader.ReadString();
                    rpcArgs.Add(key, value);
                }

                using var writer = new PacketWriter();
                writer.WriteByte(0);
                writer.WriteInt(rpcId);

                if (rpcName == "player_list")
                {
                    var characters = LuaSerializer.Serialize(Array.Empty<object>());
                    writer.WriteString("cost = 1\n" +
                                       "mb = 0\n" +
                                       "isAuctionClose = false\n" +
                                       "isPetClose = false\n" +
                                       "isColseAccount = false\n" +
                                       "beginColseAccountTime = 0\n" +
                                       "endColseAccountTime = 0\n" +
                                       "bannedReason = \"\"\n" +
                                       "sysTimeNow = 0\n" +
                                       "characters = " + characters + "\n" +
                                       "lastPid = 0");
                    await SendAsync(writer);
                }
                else if (rpcName == "sysavatar_list")
                {
                    var config = _sysAvatarPayloadMonitor.CurrentValue;
                    var configAvatarId = int.TryParse(rpcArgs.GetValueOrDefault("sysCharacterId"), out var parsedId) ? parsedId : 1;

                    if (config.SysAvatarListPayloads.TryGetValue(configAvatarId, out var rawPayload) &&
                        !string.IsNullOrWhiteSpace(rawPayload) &&
                        rawPayload.Contains("sysAvatar", StringComparison.Ordinal))
                    {
                        writer.WriteString(rawPayload);
                        await SendAsync(writer);
                        return;
                    }

                    Log.Warning("[UDP:{Remote}] sysavatar_list missing payload override for sysCharacterId={SysCharacterId}",
                        _session.RemoteEndPoint,
                        configAvatarId);
                    writer.WriteString("sysAvatar = {}\nweapons = {}");
                    await SendAsync(writer);
                }

                break;
            }
            default:
                Log.Warning("[UDP:{Remote}] Unknown packetId={PacketId} (len={Len})",
                    _session.RemoteEndPoint, packetId, reader.Remaining + 1);
                break;
        }
    }

    private Task SendAsync(PacketWriter writer)
    {
        var payload = writer.ToBuffer();
        _session.EnqueueVleMessage(payload);
        return Task.CompletedTask;
    }
}
