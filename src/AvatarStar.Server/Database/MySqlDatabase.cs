using MySqlConnector;

namespace AvatarStar.Server.Database;

public static class MySqlDatabase
{
    public const string ConnectionStringEnvironmentVariable = "AS_MYSQL_CONNECTION_STRING";

    public static string GetConnectionString()
    {
        var connectionString = Environment.GetEnvironmentVariable(ConnectionStringEnvironmentVariable);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                $"MySQL connection string is missing. Set {ConnectionStringEnvironmentVariable}.");
        }

        return connectionString;
    }

    public static MySqlConnection CreateConnection()
    {
        return new MySqlConnection(GetConnectionString());
    }
}
