using System.IO;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace AvatarStar.Server.Game.Resources;

internal sealed class ShopConfigHotReloadService : BackgroundService
{
    private static readonly TimeSpan DebounceDelay = TimeSpan.FromMilliseconds(250);
    private static readonly TimeSpan RetryDelay = TimeSpan.FromMilliseconds(150);

    private readonly ILogger<ShopConfigHotReloadService> _logger;
    private readonly object _gate = new();
    private FileSystemWatcher? _watcher;
    private CancellationTokenSource? _debounceCts;

    public ShopConfigHotReloadService(ILogger<ShopConfigHotReloadService> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var enabled = (Environment.GetEnvironmentVariable("AS_SHOP_HOTRELOAD") ?? "1")
            .Equals("1", StringComparison.OrdinalIgnoreCase);
        if (!enabled)
        {
            _logger.LogInformation("Shop config hot reload disabled (AS_SHOP_HOTRELOAD!=1)");
            return;
        }

        var path = ShopItemDatabase.GetActiveConfigPath();
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
        {
            _logger.LogWarning("Shop config hot reload disabled; config file not found at {ShopConfigPath}", path);
            return;
        }

        var directory = Path.GetDirectoryName(path);
        var fileName = Path.GetFileName(path);
        if (string.IsNullOrWhiteSpace(directory) || string.IsNullOrWhiteSpace(fileName))
        {
            _logger.LogWarning("Shop config hot reload disabled; invalid config path {ShopConfigPath}", path);
            return;
        }

        _watcher = new FileSystemWatcher(directory, fileName)
        {
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.Size,
            IncludeSubdirectories = false,
            EnableRaisingEvents = true
        };

        _watcher.Changed += OnChanged;
        _watcher.Created += OnChanged;
        _watcher.Renamed += OnRenamed;
        _watcher.Deleted += OnChanged;
        _watcher.Error += OnError;

        _logger.LogInformation("Watching shop config for changes: {ShopConfigPath}", path);

        try
        {
            await Task.Delay(Timeout.InfiniteTimeSpan, stoppingToken);
        }
        catch (OperationCanceledException)
        {
            // Normal shutdown.
        }
    }

    public override Task StopAsync(CancellationToken cancellationToken)
    {
        try
        {
            if (_watcher is not null)
            {
                _watcher.EnableRaisingEvents = false;
                _watcher.Changed -= OnChanged;
                _watcher.Created -= OnChanged;
                _watcher.Renamed -= OnRenamed;
                _watcher.Deleted -= OnChanged;
                _watcher.Error -= OnError;
                _watcher.Dispose();
            }
        }
        catch
        {
            // Ignore shutdown errors.
        }

        lock (_gate)
        {
            _debounceCts?.Cancel();
            _debounceCts?.Dispose();
            _debounceCts = null;
        }

        return base.StopAsync(cancellationToken);
    }

    private void OnChanged(object sender, FileSystemEventArgs e) => ScheduleReload();

    private void OnRenamed(object sender, RenamedEventArgs e) => ScheduleReload();

    private void OnError(object sender, ErrorEventArgs e)
    {
        _logger.LogWarning(e.GetException(), "Shop config file watcher error; hot reload may stop working");
    }

    private void ScheduleReload()
    {
        CancellationToken token;
        lock (_gate)
        {
            _debounceCts?.Cancel();
            _debounceCts?.Dispose();
            _debounceCts = new CancellationTokenSource();
            token = _debounceCts.Token;
        }

        _ = Task.Run(async () =>
        {
            try
            {
                await Task.Delay(DebounceDelay, token);
                await ReloadWithRetriesAsync(token);
            }
            catch (OperationCanceledException)
            {
                // Debounced by a newer event or shutdown.
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Unhandled exception while reloading shop config; keeping previous config");
            }
        }, CancellationToken.None);
    }

    private async Task ReloadWithRetriesAsync(CancellationToken token)
    {
        const int maxAttempts = 10;
        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            token.ThrowIfCancellationRequested();

            if (ShopItemDatabase.ReloadFromJsonConfig())
            {
                _logger.LogInformation(
                    "Reloaded shop config successfully (rev={ShopConfigRev})",
                    ShopItemDatabase.GetConfigRevision());
                return;
            }

            await Task.Delay(RetryDelay, token);
        }

        _logger.LogWarning(
            "Failed to reload shop config after change; keeping previous config (rev={ShopConfigRev})",
            ShopItemDatabase.GetConfigRevision());
    }
}

