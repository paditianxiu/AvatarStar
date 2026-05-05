using System.Text.Json;
using AvatarStar.Server.Database;
using MySqlConnector;

namespace AvatarStar.Server.Game;

internal sealed class GameDataRepository
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false
    };

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        foreach (var sql in SchemaStatements)
        {
            await using var command = new MySqlCommand(sql, connection);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        await EnsureCharacterNameUniqueIndexAsync(connection, cancellationToken);
    }

    public async Task<PlayerStoreSnapshot?> LoadAccountAsync(
        long accountId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new MySqlCommand(
            "SELECT snapshot_json FROM game_player_profiles WHERE account_id = @account_id LIMIT 1;",
            connection);
        command.Parameters.AddWithValue("@account_id", accountId);

        var snapshotJson = await command.ExecuteScalarAsync(cancellationToken) as string;
        if (string.IsNullOrWhiteSpace(snapshotJson))
        {
            return null;
        }

        return JsonSerializer.Deserialize<PlayerStoreSnapshot>(snapshotJson, JsonOptions);
    }

    public async Task<int> GetNextCharacterIdAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new MySqlCommand(
            "SELECT COALESCE(MAX(character_id), 0) + 1 FROM game_characters;",
            connection);
        return Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
    }

    public async Task<bool> CharacterNameExistsAsync(
        string name,
        CancellationToken cancellationToken = default)
    {
        name = name.Trim();
        if (name.Length == 0)
        {
            return false;
        }

        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new MySqlCommand(
            "SELECT 1 FROM game_characters WHERE name = @name LIMIT 1;",
            connection);
        command.Parameters.AddWithValue("@name", name);

        return await command.ExecuteScalarAsync(cancellationToken) is not null;
    }

    public async Task SaveAccountAsync(
        long accountId,
        PlayerStoreSnapshot snapshot,
        CancellationToken cancellationToken = default)
    {
        var snapshotJson = JsonSerializer.Serialize(snapshot, JsonOptions);

        await using var connection = MySqlDatabase.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        try
        {
            await UpsertProfileAsync(connection, transaction, accountId, snapshotJson, cancellationToken);
            await ReplaceCharactersAsync(connection, transaction, accountId, snapshot, cancellationToken);
            await ReplaceInventoryItemsAsync(connection, transaction, accountId, snapshot, cancellationToken);

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static async Task UpsertProfileAsync(
        MySqlConnection connection,
        MySqlTransaction transaction,
        long accountId,
        string snapshotJson,
        CancellationToken cancellationToken)
    {
        await using var command = new MySqlCommand(
            """
            INSERT INTO game_player_profiles (account_id, snapshot_json, created_at, updated_at)
            VALUES (@account_id, @snapshot_json, UTC_TIMESTAMP(6), UTC_TIMESTAMP(6))
            ON DUPLICATE KEY UPDATE
                snapshot_json = VALUES(snapshot_json),
                updated_at = UTC_TIMESTAMP(6);
            """,
            connection,
            transaction);
        command.Parameters.AddWithValue("@account_id", accountId);
        command.Parameters.AddWithValue("@snapshot_json", snapshotJson);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task ReplaceCharactersAsync(
        MySqlConnection connection,
        MySqlTransaction transaction,
        long accountId,
        PlayerStoreSnapshot snapshot,
        CancellationToken cancellationToken)
    {
        await using (var delete = new MySqlCommand(
                         "DELETE FROM game_characters WHERE account_id = @account_id;",
                         connection,
                         transaction))
        {
            delete.Parameters.AddWithValue("@account_id", accountId);
            await delete.ExecuteNonQueryAsync(cancellationToken);
        }

        foreach (var player in snapshot.Players)
        {
            var character = player.Character;
            await using var insert = new MySqlCommand(
                """
                INSERT INTO game_characters
                    (account_id, character_id, name, level, occupation, battle_force, max_health, character_json, created_at, updated_at)
                VALUES
                    (@account_id, @character_id, @name, @level, @occupation, @battle_force, @max_health, @character_json, UTC_TIMESTAMP(6), UTC_TIMESTAMP(6));
                """,
                connection,
                transaction);
            insert.Parameters.AddWithValue("@account_id", accountId);
            insert.Parameters.AddWithValue("@character_id", character.Id);
            insert.Parameters.AddWithValue("@name", character.Name);
            insert.Parameters.AddWithValue("@level", character.Level);
            insert.Parameters.AddWithValue("@occupation", character.Occupation);
            insert.Parameters.AddWithValue("@battle_force", character.BattleForce);
            insert.Parameters.AddWithValue("@max_health", character.MaxHealth);
            insert.Parameters.AddWithValue("@character_json", JsonSerializer.Serialize(character, JsonOptions));
            await insert.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    private static async Task ReplaceInventoryItemsAsync(
        MySqlConnection connection,
        MySqlTransaction transaction,
        long accountId,
        PlayerStoreSnapshot snapshot,
        CancellationToken cancellationToken)
    {
        await using (var delete = new MySqlCommand(
                         "DELETE FROM game_inventory_items WHERE account_id = @account_id;",
                         connection,
                         transaction))
        {
            delete.Parameters.AddWithValue("@account_id", accountId);
            await delete.ExecuteNonQueryAsync(cancellationToken);
        }

        foreach (var player in snapshot.Players)
        {
            foreach (var (storageType, slots) in player.Storages)
            {
                foreach (var (slot, item) in slots)
                {
                    await using var insert = new MySqlCommand(
                        """
                        INSERT INTO game_inventory_items
                            (account_id, character_id, storage_type, slot, pid, resource, subtype, grade, quantity, sid, item_type, item_json, created_at, updated_at)
                        VALUES
                            (@account_id, @character_id, @storage_type, @slot, @pid, @resource, @subtype, @grade, @quantity, @sid, @item_type, @item_json, UTC_TIMESTAMP(6), UTC_TIMESTAMP(6));
                        """,
                        connection,
                        transaction);
                    insert.Parameters.AddWithValue("@account_id", accountId);
                    insert.Parameters.AddWithValue("@character_id", player.Character.Id);
                    insert.Parameters.AddWithValue("@storage_type", storageType);
                    insert.Parameters.AddWithValue("@slot", slot);
                    insert.Parameters.AddWithValue("@pid", item.Pid);
                    insert.Parameters.AddWithValue("@resource", item.Resource);
                    insert.Parameters.AddWithValue("@subtype", item.SubType > 0 ? item.SubType : item.Subtype);
                    insert.Parameters.AddWithValue("@grade", item.Grade);
                    insert.Parameters.AddWithValue("@quantity", item.Quantity);
                    insert.Parameters.AddWithValue("@sid", item.Sid);
                    insert.Parameters.AddWithValue("@item_type", item.Type);
                    insert.Parameters.AddWithValue("@item_json", JsonSerializer.Serialize(item, JsonOptions));
                    await insert.ExecuteNonQueryAsync(cancellationToken);
                }
            }
        }
    }

    private static async Task EnsureCharacterNameUniqueIndexAsync(
        MySqlConnection connection,
        CancellationToken cancellationToken)
    {
        await using var command = new MySqlCommand(
            """
            CREATE UNIQUE INDEX ux_game_characters_name ON game_characters (name);
            """,
            connection);

        try
        {
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        catch (MySqlException ex) when (ex.Number == 1061)
        {
            // Index already exists.
        }
    }

    private static readonly string[] SchemaStatements =
    [
        """
        CREATE TABLE IF NOT EXISTS game_player_profiles (
            account_id BIGINT NOT NULL,
            snapshot_json JSON NOT NULL,
            created_at DATETIME(6) NOT NULL,
            updated_at DATETIME(6) NOT NULL,
            PRIMARY KEY (account_id),
            CONSTRAINT fk_game_player_profiles_account
                FOREIGN KEY (account_id) REFERENCES accounts (id)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """,
        """
        CREATE TABLE IF NOT EXISTS game_characters (
            account_id BIGINT NOT NULL,
            character_id INT NOT NULL,
            name VARCHAR(64) NOT NULL,
            level INT NOT NULL,
            occupation INT NOT NULL,
            battle_force VARCHAR(32) NOT NULL,
            max_health INT NOT NULL,
            character_json JSON NOT NULL,
            created_at DATETIME(6) NOT NULL,
            updated_at DATETIME(6) NOT NULL,
            PRIMARY KEY (account_id, character_id),
            UNIQUE KEY ux_game_characters_name (name),
            CONSTRAINT fk_game_characters_account
                FOREIGN KEY (account_id) REFERENCES accounts (id)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """,
        """
        CREATE TABLE IF NOT EXISTS game_inventory_items (
            account_id BIGINT NOT NULL,
            character_id INT NOT NULL,
            storage_type INT NOT NULL,
            slot INT NOT NULL,
            pid VARCHAR(32) NOT NULL,
            resource VARCHAR(128) NOT NULL,
            subtype INT NOT NULL,
            grade INT NOT NULL,
            quantity INT NOT NULL,
            sid INT NOT NULL,
            item_type INT NOT NULL,
            item_json JSON NOT NULL,
            created_at DATETIME(6) NOT NULL,
            updated_at DATETIME(6) NOT NULL,
            PRIMARY KEY (account_id, character_id, storage_type, slot),
            KEY ix_game_inventory_items_pid (pid),
            KEY ix_game_inventory_items_resource (resource),
            CONSTRAINT fk_game_inventory_items_account
                FOREIGN KEY (account_id) REFERENCES accounts (id)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """
    ];
}
