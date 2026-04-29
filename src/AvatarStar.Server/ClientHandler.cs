namespace AvatarStar.Server;

public class ClientHandler
{
    private readonly HashSet<Client> _clients;

    public ClientHandler()
    {
        _clients = new HashSet<Client>();
    }

    public Client AddClient(Client client)
    {
        _clients.Add(client);
        return client;
    }

    public void RemoveClient(Client client)
    {
        _clients.Remove(client);
    }

    /// <summary>
    /// 向所有游戏客户端广播房间列表已更改的通知
    /// </summary>
    public void BroadcastRoomListChanged(Client? except = null)
    {
        foreach (var client in _clients)
        {
            if (ReferenceEquals(client, except))
            {
                continue;
            }

            _ = client.SendRoomListChangedNotificationAsync();
        }
    }
}
