using System.Net;
using System.Net.Sockets;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace AvatarStar.Server.Game;

internal sealed class ChannelServerService : BackgroundService
{
    private readonly ILogger<ChannelServerService> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly PracticeRoomManager _practiceRoomManager;

    public ChannelServerService(
        ILogger<ChannelServerService> logger,
        IServiceProvider serviceProvider,
        PracticeRoomManager practiceRoomManager)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
        _practiceRoomManager = practiceRoomManager;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Starting practice-room channel server");

        var clientHandler = new ClientHandler();
        var server = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);

        server.Bind(new IPEndPoint(IPAddress.Any, _practiceRoomManager.ChannelPort));
        server.Listen(10);

        _logger.LogInformation("Practice-room channel listening on *:{Port}", _practiceRoomManager.ChannelPort);

        while (!stoppingToken.IsCancellationRequested)
        {
            var clientSocket = await server.AcceptAsync(stoppingToken);
            var client = ActivatorUtilities.CreateInstance<ChannelClient>(_serviceProvider, clientHandler, clientSocket);

            clientHandler.AddClient(client);
            _logger.LogInformation("Accepted channel connection from {Ip}:{Port}",
                client.RemoteEndPoint.Address, client.RemoteEndPoint.Port);

            client.Start();
        }
    }
}
