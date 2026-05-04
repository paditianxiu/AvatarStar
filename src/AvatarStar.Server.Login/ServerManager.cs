using AvatarStar.Server.Persistence;
using Serilog;

namespace AvatarStar.Server.Login;

public class ServerManager
{
    private static readonly ServerCategory[] FallbackServers = [
        new ServerCategory(1, "Category", [
            new ServerEntry(1, "Server 1", "127.0.0.1", 1234, 0),
            new ServerEntry(2, "Server 2", "127.0.0.1", 1234, 51),
            new ServerEntry(3, "Server 3", "127.0.0.1", 1234, 81),
            new ServerEntry(4, "Server 4", "127.0.0.1", 1234, 255),
        ]),
        new ServerCategory(2, "Category 2", [
            new ServerEntry(5, "Server 5", "127.0.0.1", 1234, 0),
            new ServerEntry(6, "Server 6", "127.0.0.1", 1234, 51)
        ])
    ];

    public static ServerCategory[] Servers => GetServers();

    public static ServerCategory[] GetServers()
    {
        try
        {
            using var db = new AvatarStarDbContext();
            var categories = db.ServerCategories.OrderBy(x => x.SortOrder).ThenBy(x => x.Id).ToArray();
            if (categories.Length == 0)
            {
                return FallbackServers;
            }

            var serversByCategory = db.ServerEntries
                .Where(x => x.Enabled != 0)
                .ToArray()
                .GroupBy(x => x.CategoryId)
                .ToDictionary(x => x.Key, x => x.OrderBy(s => s.SortOrder).ThenBy(s => s.Id).ToArray());
            var result = categories
                .Select(category =>
                {
                    serversByCategory.TryGetValue(category.Id, out var servers);
                    return new ServerCategory(
                        (byte)Math.Clamp(category.Id, 0, byte.MaxValue),
                        category.Name,
                        (servers ?? Array.Empty<ServerEntryEntity>())
                            .Select(server => new ServerEntry(
                                (byte)Math.Clamp(server.Id, 0, byte.MaxValue),
                                server.Name,
                                server.Ip,
                                server.Port,
                                (byte)Math.Clamp(server.Status, 0, byte.MaxValue)))
                            .ToArray());
                })
                .Where(category => category.Servers.Length > 0)
                .ToArray();
            return result.Length > 0 ? result : FallbackServers;
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load server list from database; falling back to built-in defaults.");
            return FallbackServers;
        }
    }
}
