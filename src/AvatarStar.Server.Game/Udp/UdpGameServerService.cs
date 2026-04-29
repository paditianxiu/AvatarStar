using System.Buffers;
using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace AvatarStar.Server.Game.Udp;

public sealed class UdpGameServerService : BackgroundService
{
    private readonly ILogger<UdpGameServerService> _logger;
    private readonly IServiceProvider _serviceProvider;

    public UdpGameServerService(ILogger<UdpGameServerService> logger, IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Starting UDP listener");

        using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
        socket.Bind(new IPEndPoint(IPAddress.Any, 9532));

        _logger.LogInformation("Listening (UDP) on *:9532");

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
                _logger.LogInformation("New UDP session from {Remote}", ep);

                var session = new UdpReliableSession(ep);
                var client = ActivatorUtilities.CreateInstance<LegacyUdpGameClient>(_serviceProvider, session);
                return new SessionContext(session, client);
            });

            var nowUtc = DateTime.UtcNow;
            var processed = ctx.Session.ProcessIncomingDatagram(bufferOwner.Memory.Slice(0, result.ReceivedBytes).Span, nowUtc);
            await SendDatagramsAsync(socket, remoteKey, processed.OutboundDatagrams, stoppingToken);

            foreach (var packet in processed.Packets)
            {
                await ctx.Client.HandleAsync(packet);
            }

            // Flush any client responses that were queued while handling packets.
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
                // Drop inactive sessions.
                if (ctx.Session.LastRecvAtUtc != DateTime.MinValue && nowUtc - ctx.Session.LastRecvAtUtc > TimeSpan.FromMinutes(2))
                {
                    if (sessions.TryRemove(remote, out var removed))
                    {
                        removed.Session.Dispose();
                        _logger.LogInformation("Removed UDP session {Remote} due to inactivity", remote);
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

    private sealed record SessionContext(UdpReliableSession Session, LegacyUdpGameClient Client);

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
