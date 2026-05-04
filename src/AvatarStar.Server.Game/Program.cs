using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;
using AvatarStar.Server.Game.Udp;
using AvatarStar.Server.Persistence;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;

var logDirectory = ResolveLogDirectory();

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File(
        Path.Combine(logDirectory, "game-.log"),
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 14,
        shared: true,
        flushToDiskInterval: TimeSpan.FromSeconds(1))
    .CreateLogger();

try
{
    new DatabaseInitializer().Initialize();

    var builder = Host.CreateApplicationBuilder(args);

    var configDirectory = Path.Combine(AppContext.BaseDirectory, "Config");
    if (!Directory.Exists(configDirectory))
    {
        // Fallback for running from repo root (or other working directories).
        configDirectory = Path.Combine(Directory.GetCurrentDirectory(), "Config");
    }

    Log.Information("Loading sysavatar_list payloads from {ConfigDirectory}", Path.Combine(configDirectory, "SysAvatarPayloads"));
    builder.Configuration.AddEnvironmentVariables(prefix: "AS_");
    builder.Configuration.AddCommandLine(args);

    var shopConfigPath = ShopItemDatabase.GetActiveConfigPath();
    Log.Information("Shop config path: {ShopConfigPath} (exists={Exists})", shopConfigPath, File.Exists(shopConfigPath));
    Log.Information("Shop items loaded: {Count}", ShopItemDatabase.GetAllShopItems().Count);

    builder.Services.Configure<SysAvatarPayloadConfig>(_ => { });
    builder.Services.PostConfigure<SysAvatarPayloadConfig>(config =>
    {
        var loaded = SysAvatarPayloadLoader.Load(config, configDirectory);
        if (loaded > 0)
        {
            Log.Information("Loaded {Count} sysavatar_list payload override(s)", loaded);
        }
    });
    builder.Services.AddSingleton<PlayerStore>();
    builder.Services.AddSingleton<PracticeRoomManager>();
    builder.Services.AddSingleton<AccountRepository>();
    builder.Services.AddSingleton<ConfigRepository>();
    builder.Services.AddSerilog();

    var enableTcp = (Environment.GetEnvironmentVariable("AS_GAME_TCP") ?? "1").Equals("1", StringComparison.OrdinalIgnoreCase);
    var enableUdp = (Environment.GetEnvironmentVariable("AS_GAME_UDP") ?? "1").Equals("1", StringComparison.OrdinalIgnoreCase);

    if (enableTcp) builder.Services.AddHostedService<GameServerService>();
    else Log.Information("Game TCP disabled (AS_GAME_TCP!=1)");

    if (enableTcp) builder.Services.AddHostedService<ChannelServerService>();

    if (enableUdp) builder.Services.AddHostedService<UdpGameServerService>();
    else Log.Information("Game UDP disabled (AS_GAME_UDP!=1)");

    if (enableUdp) builder.Services.AddHostedService<UdpPracticeRoomChannelService>();

    builder.Services.AddHostedService<ShopConfigHotReloadService>();

    var host = builder.Build();
    await host.RunAsync();
    return 0;
}
catch (Exception ex)
{
    Log.Fatal(ex, "Host terminated unexpectedly");
    return 1;
}
finally
{
    await Log.CloseAndFlushAsync();
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
