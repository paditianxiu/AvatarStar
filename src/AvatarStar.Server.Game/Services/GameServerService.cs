using System.Net;
using System.Net.Sockets;
using AvatarStar.Server.Database;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace AvatarStar.Server.Game;

internal sealed class GameServerService : BackgroundService
{
    private readonly ILogger<GameServerService> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly AccountRepository _accountRepository;
    private readonly GameDataRepository _gameDataRepository;
    private readonly PlayerStore _playerStore;

    public GameServerService(
        ILogger<GameServerService> logger,
        IServiceProvider serviceProvider,
        AccountRepository accountRepository,
        GameDataRepository gameDataRepository,
        PlayerStore playerStore)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
        _accountRepository = accountRepository;
        _gameDataRepository = gameDataRepository;
        _playerStore = playerStore;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Starting");
        await _accountRepository.InitializeAsync(stoppingToken);
        await _gameDataRepository.InitializeAsync(stoppingToken);
        _playerStore.EnsureNextCharacterIdAtLeast(await _gameDataRepository.GetNextCharacterIdAsync(stoppingToken));
        _logger.LogInformation("MySQL game data schema initialized");

        var clientHandler = new ClientHandler();
        var server = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);

        server.Bind(new IPEndPoint(IPAddress.Any, 9532));
        server.Listen(10);

        _logger.LogInformation("Listening on *:9532");

        while (!stoppingToken.IsCancellationRequested)
        {
            var clientSocket = await server.AcceptAsync(stoppingToken);
            var client = ActivatorUtilities.CreateInstance<GameClient>(_serviceProvider, clientHandler, clientSocket);

            clientHandler.AddClient(client);
    
            _logger.LogInformation("Accepted connection from {Ip}:{Port}", client.RemoteEndPoint.Address, client.RemoteEndPoint.Port);

            client.Start();
        }
    }
}
