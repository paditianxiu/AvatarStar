using System.Buffers;
using System.Net;
using System.Net.Sockets;
using Serilog;

namespace AvatarStar.Server;

public abstract class Client
{
    private readonly ClientHandler _clientHandler;
    private readonly Socket _socket;
    private readonly CancellationTokenSource _cancellationToken;
    
    private Task? _loopTask;
    
    public Client(ClientHandler clientHandler, Socket socket)
    {
        _clientHandler = clientHandler;
        _socket = socket;
        _cancellationToken = new CancellationTokenSource();
    }
    
    public IPEndPoint RemoteEndPoint => (IPEndPoint)_socket.RemoteEndPoint!;
    public IPEndPoint LocalEndPoint => (IPEndPoint)_socket.LocalEndPoint!;

    private string RemoteLabel
    {
        get
        {
            try
            {
                return _socket.RemoteEndPoint?.ToString() ?? "<unknown>";
            }
            catch
            {
                return "<closed>";
            }
        }
    }

    /// <summary>
    ///     Start receiving data from the client.
    /// </summary>
    public void Start()
    {
        if (_loopTask != null)
        {
            return;
        }
        
        _loopTask = LoopAsync();
    }

    /// <summary>
    ///     Stop receiving data from the client.
    /// </summary>
    public Task Stop()
    {
        if (_loopTask == null)
        {
            return Task.CompletedTask;
        }
        
        _cancellationToken.Cancel();
        _clientHandler.RemoveClient(this);
        if (this is IDisconnectAwareClient disconnectAwareClient)
        {
            disconnectAwareClient.OnClientDisconnected();
        }
        try
        {
            if (_socket.Connected)
            {
                _socket.Shutdown(SocketShutdown.Both);
            }
        }
        catch
        {
        }

        try
        {
            _socket.Close();
        }
        catch
        {
        }
        
        return _loopTask;
    }

    private async Task LoopAsync()
    {
        using var buffer = CreateBuffer();
        using var temp = MemoryPool<byte>.Shared.Rent(4096);
        
        while (!_cancellationToken.IsCancellationRequested)
        {
            try
            {
                var dataLen = await _socket.ReceiveAsync(temp.Memory, _cancellationToken.Token);
                if (dataLen == 0)
                {
                    Log.Information("{ClientType} {Remote} disconnected", GetType().Name, RemoteLabel);
                    _ = Stop();
                    break;
                }

                buffer.Append(temp.Memory.Slice(0, dataLen));

                foreach (var reader in buffer.Process())
                {
                    await HandleAsync(reader);
                }
            }
            catch (SocketException e) when (
                e.SocketErrorCode == SocketError.ConnectionReset ||
                e.SocketErrorCode == SocketError.ConnectionAborted)
            {
                Log.Information("{ClientType} {Remote} disconnected", GetType().Name, RemoteLabel);
                _ = Stop();
                break;
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (ObjectDisposedException)
            {
                break;
            }
            catch (Exception e)
            {
                Log.Error(e, "{ClientType} {Remote} caught exception in client loop", GetType().Name, RemoteLabel);
            }
        }
    }

    protected abstract Task HandleAsync(PacketReader reader);
    
    protected abstract ClientBuffer CreateBuffer();

    protected void BroadcastRoomListChanged()
    {
        _clientHandler.BroadcastRoomListChanged();
    }

    public virtual Task SendRoomListChangedNotificationAsync()
    {
        return Task.CompletedTask;
    }

    protected virtual async Task SendAsync(ArraySegment<byte> data)
    {
        await _socket.SendAsync(data, SocketFlags.None);
    }

    protected virtual async Task SendAsync(PacketWriter writer)
    {
        await SendAsync(writer.ToBuffer());
    }
}
