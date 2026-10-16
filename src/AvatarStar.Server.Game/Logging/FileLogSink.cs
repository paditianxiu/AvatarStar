using System.Text;
using Serilog.Core;
using Serilog.Events;

namespace AvatarStar.Server.Game.Logging;

/// <summary>
/// 最小化的文件日志 sink：只依赖 Serilog 核心包（不额外引第三方 sink 包）。
/// 作用是把控制台里的东西同时落盘到 <c>logs/server-YYYYMMDD.log</c>，
/// 这样排查「按抓包还原协议」的问题时不用再靠人工复制控制台输出 ——
/// 封包时序（哪条包先到、客户端什么时候发 103/157）在文件里可以离线核对。
/// </summary>
public sealed class FileLogSink : ILogEventSink, IDisposable
{
    private readonly object _gate = new();
    private readonly IFormatProvider? _formatProvider;
    private readonly StreamWriter _writer;

    public FileLogSink(string path, IFormatProvider? formatProvider = null)
    {
        _formatProvider = formatProvider;

        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        // AutoFlush：服务端被强杀时也要保住已经打出来的行（排查现场全靠它）。
        _writer = new StreamWriter(new FileStream(path, FileMode.Append, FileAccess.Write, FileShare.Read))
        {
            AutoFlush = true,
        };
    }

    public void Emit(LogEvent logEvent)
    {
        var line = Format(logEvent);
        lock (_gate)
        {
            _writer.WriteLine(line);
        }
    }

    private string Format(LogEvent logEvent)
    {
        var builder = new StringBuilder(160);
        builder.Append(logEvent.Timestamp.ToString("yyyy-MM-dd HH:mm:ss.fff"));
        builder.Append(' ');
        builder.Append(ShortLevel(logEvent.Level));
        builder.Append(' ');
        builder.Append(logEvent.RenderMessage(_formatProvider));

        if (logEvent.Exception is not null)
        {
            builder.Append(Environment.NewLine).Append(logEvent.Exception);
        }

        return builder.ToString();
    }

    private static string ShortLevel(LogEventLevel level)
    {
        return level switch
        {
            LogEventLevel.Verbose => "VRB",
            LogEventLevel.Debug => "DBG",
            LogEventLevel.Information => "INF",
            LogEventLevel.Warning => "WRN",
            LogEventLevel.Error => "ERR",
            LogEventLevel.Fatal => "FTL",
            _ => "???",
        };
    }

    public void Dispose()
    {
        lock (_gate)
        {
            _writer.Dispose();
        }
    }
}
