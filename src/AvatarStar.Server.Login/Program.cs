using System.Net;
using System.Net.Sockets;
using AvatarStar.Server;
using AvatarStar.Server.Login;
using AvatarStar.Server.Persistence;
using Serilog;

var logDirectory = ResolveLogDirectory();

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Verbose()
    .WriteTo.Console()
    .WriteTo.File(
        Path.Combine(logDirectory, "login-.log"),
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 14,
        shared: true,
        flushToDiskInterval: TimeSpan.FromSeconds(1))
    .CreateLogger();

Log.Information("Starting");

new DatabaseInitializer().Initialize();
var accounts = new AccountRepository();

var clientHandler = new ClientHandler();
var server = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);

server.Bind(new IPEndPoint(IPAddress.Any, 9531));
server.Listen(10);

Log.Information("Listening on *:9531");

while (true)
{
    var clientSocket = await server.AcceptAsync();
    var client = new LoginClient(clientHandler, clientSocket, accounts);

    clientHandler.AddClient(client);
    
    Log.Information("Accepted connection from {Ip}:{Port}", client.RemoteEndPoint.Address, client.RemoteEndPoint.Port);

    client.Start();
}

static string ResolveLogDirectory()
{
    var configured = Environment.GetEnvironmentVariable("AS_LOG_DIR");
    var directory = string.IsNullOrWhiteSpace(configured)
        ? Path.Combine(ResolveProjectRoot(), "logs")
        : configured!;

    Directory.CreateDirectory(directory);
    return directory;
}

static string ResolveProjectRoot()
{
    var current = new DirectoryInfo(Directory.GetCurrentDirectory());
    while (current is not null)
    {
        if (Directory.Exists(Path.Combine(current.FullName, "src")))
        {
            return current.FullName;
        }

        current = current.Parent;
    }

    return Directory.GetCurrentDirectory();
}
