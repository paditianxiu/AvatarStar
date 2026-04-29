using System.Buffers;
using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace AvatarStar.Server.Game.Udp;

internal sealed class UdpPracticeRoomChannelService : BackgroundService
{
    private readonly ILogger<UdpPracticeRoomChannelService> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly PracticeRoomManager _practiceRoomManager;

    public UdpPracticeRoomChannelService(
        ILogger<UdpPracticeRoomChannelService> logger,
        IServiceProvider serviceProvider,
        PracticeRoomManager practiceRoomManager)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
        _practiceRoomManager = practiceRoomManager;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Starting practice-room UDP channel listener");

        using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
        socket.Bind(new IPEndPoint(IPAddress.Any, _practiceRoomManager.ChannelPort));

        _logger.LogInformation("Practice-room UDP channel listening on *:{Port}", _practiceRoomManager.ChannelPort);

        var sessions = new ConcurrentDictionary<IPEndPoint, SessionContext>(new IPEndPointComparer());

        var tickTask = TickLoopAsync(socket, sessions, stoppingToken);
        var recvTask = RecvLoopAsync(socket, sessions, stoppingToken);

        await Task.WhenAll(tickTask, recvTask);
    }

    private async Task RecvLoopAsync(
        Socket socket,
        ConcurrentDictionary<IPEndPoint, SessionContext> sessions,
        CancellationToken stoppingToken)
    {
        using var bufferOwner = MemoryPool<byte>.Shared.Rent(512);
        EndPoint any = new IPEndPoint(IPAddress.Any, 0);

        while (!stoppingToken.IsCancellationRequested)
        {
            SocketReceiveFromResult result;
            try
            {
                result = await socket.ReceiveFromAsync(bufferOwner.Memory, SocketFlags.None, any, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            var remote = (IPEndPoint)result.RemoteEndPoint;
            var remoteKey = new IPEndPoint(remote.Address, remote.Port);
            var ctx = sessions.GetOrAdd(remoteKey, ep =>
            {
                _logger.LogInformation("New practice-room UDP channel session from {Remote}", ep);

                var session = new UdpReliableSession(ep);
                var client = ActivatorUtilities.CreateInstance<LegacyUdpPracticeRoomChannelClient>(_serviceProvider, session);
                return new SessionContext(session, client);
            });

            var nowUtc = DateTime.UtcNow;
            var processed = ctx.Session.ProcessIncomingDatagram(bufferOwner.Memory.Slice(0, result.ReceivedBytes).Span, nowUtc);
            await SendDatagramsAsync(socket, remoteKey, processed.OutboundDatagrams, stoppingToken);

            foreach (var packet in processed.Packets)
            {
                await ctx.Client.HandleAsync(packet);
            }

            var flush = ctx.Session.Tick(nowUtc);
            await SendDatagramsAsync(socket, remoteKey, flush, stoppingToken);
        }
    }

    private async Task TickLoopAsync(
        Socket socket,
        ConcurrentDictionary<IPEndPoint, SessionContext> sessions,
        CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(50));

        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            var nowUtc = DateTime.UtcNow;
            foreach (var (remote, ctx) in sessions)
            {
                if (ctx.Session.LastRecvAtUtc != DateTime.MinValue &&
                    nowUtc - ctx.Session.LastRecvAtUtc > TimeSpan.FromMinutes(2))
                {
                    if (sessions.TryRemove(remote, out var removed))
                    {
                        removed.Session.Dispose();
                        _logger.LogInformation("Removed practice-room UDP channel session {Remote} due to inactivity", remote);
                    }

                    continue;
                }

                var outbound = ctx.Session.Tick(nowUtc);
                await SendDatagramsAsync(socket, remote, outbound, stoppingToken);
            }
        }
    }

    private static async Task SendDatagramsAsync(
        Socket socket,
        IPEndPoint remote,
        List<byte[]> datagrams,
        CancellationToken stoppingToken)
    {
        foreach (var datagram in datagrams)
        {
            await socket.SendToAsync(datagram, SocketFlags.None, remote, stoppingToken);
        }
    }

    private sealed record SessionContext(UdpReliableSession Session, LegacyUdpPracticeRoomChannelClient Client);

    private sealed class IPEndPointComparer : IEqualityComparer<IPEndPoint>
    {
        public bool Equals(IPEndPoint? x, IPEndPoint? y)
        {
            if (ReferenceEquals(x, y))
            {
                return true;
            }

            if (x is null || y is null)
            {
                return false;
            }

            return x.Port == y.Port && x.Address.Equals(y.Address);
        }

        public int GetHashCode(IPEndPoint obj)
        {
            return HashCode.Combine(obj.Address, obj.Port);
        }
    }
}
