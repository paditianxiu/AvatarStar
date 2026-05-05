using MySqlConnector;

namespace AvatarStar.Server.Database;

public sealed class AccountRepository
{
    private static readonly TimeSpan DefaultTokenLifetime = TimeSpan.FromHours(12);

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        foreach (var sql in SchemaStatements)
        {
            await using var command = new MySqlCommand(sql, connection);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    public async Task<(bool Created, AccountRecord? Account, string? Token)> RegisterAsync(
        string username,
        string password,
        CancellationToken cancellationToken = default)
    {
        username = NormalizeUsername(username);
        if (username.Length == 0 || string.IsNullOrEmpty(password))
        {
            return (false, null, null);
        }

        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);
        try
        {
            var existing = await FindAccountByUsernameAsync(connection, transaction, username, cancellationToken);
            if (existing is not null)
            {
                await transaction.RollbackAsync(cancellationToken);
                return (false, null, null);
            }

            var passwordHash = PasswordHasher.Hash(password);
            await using (var command = new MySqlCommand(
                             """
                             INSERT INTO accounts (username, password_hash, created_at, updated_at)
                             VALUES (@username, @password_hash, UTC_TIMESTAMP(6), UTC_TIMESTAMP(6));
                             """,
                             connection,
                             transaction))
            {
                command.Parameters.AddWithValue("@username", username);
                command.Parameters.AddWithValue("@password_hash", passwordHash);
                await command.ExecuteNonQueryAsync(cancellationToken);
                var id = command.LastInsertedId;
                var account = new AccountRecord(id, username);
                var token = await IssueTokenAsync(connection, transaction, account.Id, cancellationToken);

                await transaction.CommitAsync(cancellationToken);
                return (true, account, token);
            }
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<(bool Success, AccountRecord? Account, string? Token)> LoginAsync(
        string username,
        string password,
        CancellationToken cancellationToken = default)
    {
        username = NormalizeUsername(username);
        if (username.Length == 0 || string.IsNullOrEmpty(password))
        {
            return (false, null, null);
        }

        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);
        try
        {
            var stored = await FindAccountWithPasswordAsync(connection, transaction, username, cancellationToken);
            if (stored is null || !PasswordHasher.Verify(password, stored.PasswordHash))
            {
                await transaction.RollbackAsync(cancellationToken);
                return (false, null, null);
            }

            var account = new AccountRecord(stored.Id, stored.Username);
            var token = await IssueTokenAsync(connection, transaction, account.Id, cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return (true, account, token);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<AuthTokenRecord?> ValidateTokenAsync(
        string token,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return null;
        }

        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var tokenHash = TokenHasher.Hash(token);
        await using var command = new MySqlCommand(
            """
            SELECT t.account_id, a.username, t.expires_at
            FROM auth_tokens t
            INNER JOIN accounts a ON a.id = t.account_id
            WHERE t.token_hash = @token_hash
              AND t.revoked_at IS NULL
              AND t.expires_at > UTC_TIMESTAMP(6)
            LIMIT 1;
            """,
            connection);
        command.Parameters.AddWithValue("@token_hash", tokenHash);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new AuthTokenRecord(
            reader.GetInt64("account_id"),
            reader.GetString("username"),
            DateTime.SpecifyKind(reader.GetDateTime("expires_at"), DateTimeKind.Utc));
    }

    public static string NormalizeUsername(string username)
    {
        return username.Trim();
    }

    private static async Task<AccountRecord?> FindAccountByUsernameAsync(
        MySqlConnection connection,
        MySqlTransaction transaction,
        string username,
        CancellationToken cancellationToken)
    {
        await using var command = new MySqlCommand(
            "SELECT id, username FROM accounts WHERE username = @username LIMIT 1;",
            connection,
            transaction);
        command.Parameters.AddWithValue("@username", username);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new AccountRecord(reader.GetInt64("id"), reader.GetString("username"));
    }

    private static async Task<AccountWithPassword?> FindAccountWithPasswordAsync(
        MySqlConnection connection,
        MySqlTransaction transaction,
        string username,
        CancellationToken cancellationToken)
    {
        await using var command = new MySqlCommand(
            "SELECT id, username, password_hash FROM accounts WHERE username = @username LIMIT 1;",
            connection,
            transaction);
        command.Parameters.AddWithValue("@username", username);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new AccountWithPassword(
            reader.GetInt64("id"),
            reader.GetString("username"),
            reader.GetString("password_hash"));
    }

    private static async Task<string> IssueTokenAsync(
        MySqlConnection connection,
        MySqlTransaction transaction,
        long accountId,
        CancellationToken cancellationToken)
    {
        var token = $"as_{Guid.NewGuid():N}{Guid.NewGuid():N}";
        var tokenHash = TokenHasher.Hash(token);
        var expiresAt = DateTime.UtcNow.Add(DefaultTokenLifetime);

        await using var command = new MySqlCommand(
            """
            INSERT INTO auth_tokens (account_id, token_hash, expires_at, created_at)
            VALUES (@account_id, @token_hash, @expires_at, UTC_TIMESTAMP(6));
            """,
            connection,
            transaction);
        command.Parameters.AddWithValue("@account_id", accountId);
        command.Parameters.AddWithValue("@token_hash", tokenHash);
        command.Parameters.AddWithValue("@expires_at", expiresAt);
        await command.ExecuteNonQueryAsync(cancellationToken);

        return token;
    }

    private sealed record AccountWithPassword(long Id, string Username, string PasswordHash);

    private static readonly string[] SchemaStatements =
    [
        """
        CREATE TABLE IF NOT EXISTS accounts (
            id BIGINT NOT NULL AUTO_INCREMENT,
            username VARCHAR(64) NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            created_at DATETIME(6) NOT NULL,
            updated_at DATETIME(6) NOT NULL,
            PRIMARY KEY (id),
            UNIQUE KEY ux_accounts_username (username)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """,
        """
        CREATE TABLE IF NOT EXISTS auth_tokens (
            id BIGINT NOT NULL AUTO_INCREMENT,
            account_id BIGINT NOT NULL,
            token_hash CHAR(64) NOT NULL,
            expires_at DATETIME(6) NOT NULL,
            created_at DATETIME(6) NOT NULL,
            revoked_at DATETIME(6) NULL,
            PRIMARY KEY (id),
            UNIQUE KEY ux_auth_tokens_token_hash (token_hash),
            KEY ix_auth_tokens_account_id (account_id),
            KEY ix_auth_tokens_expires_at (expires_at),
            CONSTRAINT fk_auth_tokens_account
                FOREIGN KEY (account_id) REFERENCES accounts (id)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """
    ];
}
