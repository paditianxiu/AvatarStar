using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Serilog;

namespace AvatarStar.Server.Persistence;

public sealed class AvatarStarDbContext : DbContext
{
    private readonly string _dbPath;

    public AvatarStarDbContext(string? dbPath = null)
    {
        _dbPath = AvatarStarDatabase.ResolveDatabasePath(dbPath);
    }

    public DbSet<AccountEntity> Accounts => Set<AccountEntity>();
    public DbSet<AuthSessionEntity> AuthSessions => Set<AuthSessionEntity>();
    public DbSet<CharacterEntity> Characters => Set<CharacterEntity>();
    public DbSet<InventoryItemEntity> InventoryItems => Set<InventoryItemEntity>();
    public DbSet<EquippedItemEntity> EquippedItems => Set<EquippedItemEntity>();
    public DbSet<HotkeySlotEntity> HotkeySlots => Set<HotkeySlotEntity>();
    public DbSet<CharacterSkillLevelEntity> CharacterSkillLevels => Set<CharacterSkillLevelEntity>();
    public DbSet<SkillDefinitionEntity> SkillDefinitions => Set<SkillDefinitionEntity>();
    public DbSet<OnlineRewardRuleEntity> OnlineRewardRules => Set<OnlineRewardRuleEntity>();
    public DbSet<OnlineRewardPrizeEntity> OnlineRewardPrizes => Set<OnlineRewardPrizeEntity>();
    public DbSet<CharacterOnlineRewardStateEntity> CharacterOnlineRewardStates => Set<CharacterOnlineRewardStateEntity>();
    public DbSet<CheckinConfigEntity> CheckinConfig => Set<CheckinConfigEntity>();
    public DbSet<CheckinEntryEntity> CheckinEntries => Set<CheckinEntryEntity>();
    public DbSet<CheckinRewardEntity> CheckinRewards => Set<CheckinRewardEntity>();
    public DbSet<CharacterCheckinDayEntity> CharacterCheckinDays => Set<CharacterCheckinDayEntity>();
    public DbSet<CharacterCheckinClaimEntity> CharacterCheckinClaims => Set<CharacterCheckinClaimEntity>();
    public DbSet<BoxCategoryEntity> BoxCategories => Set<BoxCategoryEntity>();
    public DbSet<BoxPointRuleEntity> BoxPointRules => Set<BoxPointRuleEntity>();
    public DbSet<BoxPrizeEntity> BoxPrizes => Set<BoxPrizeEntity>();
    public DbSet<CharacterBoxPointEntity> CharacterBoxPoints => Set<CharacterBoxPointEntity>();
    public DbSet<CharacterBoxPointClaimEntity> CharacterBoxPointClaims => Set<CharacterBoxPointClaimEntity>();
    public DbSet<ShopItemEntity> ShopItems => Set<ShopItemEntity>();
    public DbSet<ShopPriceEntity> ShopPrices => Set<ShopPriceEntity>();
    public DbSet<CharacterShopPurchaseEntity> CharacterShopPurchases => Set<CharacterShopPurchaseEntity>();
    public DbSet<GameTextEntity> GameTexts => Set<GameTextEntity>();
    public DbSet<LobbyLevelEntity> LobbyLevels => Set<LobbyLevelEntity>();
    public DbSet<ConfigDocumentEntity> ConfigDocuments => Set<ConfigDocumentEntity>();
    public DbSet<ServerCategoryEntity> ServerCategories => Set<ServerCategoryEntity>();
    public DbSet<ServerEntryEntity> ServerEntries => Set<ServerEntryEntity>();
    public DbSet<ServerSettingEntity> ServerSettings => Set<ServerSettingEntity>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseSqlite($"Data Source={_dbPath}");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AccountEntity>(e =>
        {
            e.ToTable("accounts");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.Username).IsUnique();
        });

        modelBuilder.Entity<AuthSessionEntity>(e =>
        {
            e.ToTable("auth_sessions");
            e.HasKey(x => x.Token);
            e.HasIndex(x => x.AccountId);
        });

        modelBuilder.Entity<CharacterEntity>(e =>
        {
            e.ToTable("characters");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.HasIndex(x => x.AccountId).HasDatabaseName("idx_characters_account_id");
            e.HasIndex(x => x.DeletedAt).HasDatabaseName("idx_characters_deleted_at");
        });

        modelBuilder.Entity<InventoryItemEntity>(e =>
        {
            e.ToTable("inventory_items");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.CharacterId, x.Pid }).IsUnique().HasDatabaseName("uq_inventory_character_pid");
            e.HasIndex(x => new { x.CharacterId, x.StorageType, x.Slot }).IsUnique().HasDatabaseName("uq_inventory_character_storage_slot");
        });

        modelBuilder.Entity<EquippedItemEntity>(e =>
        {
            e.ToTable("equipped_items");
            e.HasKey(x => new { x.CharacterId, x.EquipType });
        });

        modelBuilder.Entity<HotkeySlotEntity>(e =>
        {
            e.ToTable("hotkey_slots");
            e.HasKey(x => new { x.CharacterId, x.Slot });
        });

        modelBuilder.Entity<CharacterSkillLevelEntity>(e =>
        {
            e.ToTable("character_skill_levels");
            e.HasKey(x => new { x.CharacterId, x.SkillId });
        });

        modelBuilder.Entity<SkillDefinitionEntity>(e =>
        {
            e.ToTable("skill_definitions");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
        });

        modelBuilder.Entity<OnlineRewardRuleEntity>(e =>
        {
            e.ToTable("online_reward_rules");
            e.HasKey(x => x.PrizeLevel);
            e.Property(x => x.PrizeLevel).ValueGeneratedNever();
        });

        modelBuilder.Entity<OnlineRewardPrizeEntity>(e =>
        {
            e.ToTable("online_reward_prizes");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.HasIndex(x => x.PrizeLevel);
        });

        modelBuilder.Entity<CharacterOnlineRewardStateEntity>(e =>
        {
            e.ToTable("character_online_reward_state");
            e.HasKey(x => x.CharacterId);
            e.Property(x => x.CharacterId).ValueGeneratedNever();
        });

        modelBuilder.Entity<CheckinConfigEntity>(e =>
        {
            e.ToTable("checkin_config");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
        });

        modelBuilder.Entity<CheckinEntryEntity>(e =>
        {
            e.ToTable("checkin_entries");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
        });

        modelBuilder.Entity<CheckinRewardEntity>(e =>
        {
            e.ToTable("checkin_rewards");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.HasIndex(x => x.CheckinEntryId);
        });

        modelBuilder.Entity<CharacterCheckinDayEntity>(e =>
        {
            e.ToTable("character_checkin_days");
            e.HasKey(x => new { x.CharacterId, x.MonthKey, x.Day });
        });

        modelBuilder.Entity<CharacterCheckinClaimEntity>(e =>
        {
            e.ToTable("character_checkin_claims");
            e.HasKey(x => new { x.CharacterId, x.MonthKey, x.CheckinId });
        });

        modelBuilder.Entity<BoxCategoryEntity>(e =>
        {
            e.ToTable("box_categories");
            e.HasKey(x => x.Category);
            e.Property(x => x.Category).ValueGeneratedNever();
        });

        modelBuilder.Entity<BoxPointRuleEntity>(e =>
        {
            e.ToTable("box_point_rules");
            e.HasKey(x => new { x.BoxCategory, x.GiftCategory });
        });

        modelBuilder.Entity<BoxPrizeEntity>(e =>
        {
            e.ToTable("box_prizes");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.HasIndex(x => new { x.Category, x.PoolType });
        });

        modelBuilder.Entity<CharacterBoxPointEntity>(e =>
        {
            e.ToTable("character_box_points");
            e.HasKey(x => new { x.CharacterId, x.Category });
        });

        modelBuilder.Entity<CharacterBoxPointClaimEntity>(e =>
        {
            e.ToTable("character_box_point_claims");
            e.HasKey(x => new { x.CharacterId, x.Category, x.Threshold });
        });

        modelBuilder.Entity<ShopItemEntity>(e =>
        {
            e.ToTable("shop_items");
            e.HasKey(x => x.Sid);
            e.Property(x => x.Sid).ValueGeneratedNever();
        });

        modelBuilder.Entity<ShopPriceEntity>(e =>
        {
            e.ToTable("shop_prices");
            e.HasKey(x => new { x.Sid, x.PriceId });
        });

        modelBuilder.Entity<CharacterShopPurchaseEntity>(e =>
        {
            e.ToTable("character_shop_purchases");
            e.HasKey(x => new { x.CharacterId, x.Sid, x.PriceId });
        });

        modelBuilder.Entity<GameTextEntity>(e =>
        {
            e.ToTable("game_texts");
            e.HasKey(x => x.TextId);
        });

        modelBuilder.Entity<LobbyLevelEntity>(e =>
        {
            e.ToTable("lobby_levels");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
        });

        modelBuilder.Entity<ConfigDocumentEntity>(e =>
        {
            e.ToTable("config_documents");
            e.HasKey(x => x.Key);
        });

        modelBuilder.Entity<ServerCategoryEntity>(e =>
        {
            e.ToTable("server_categories");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
        });

        modelBuilder.Entity<ServerEntryEntity>(e =>
        {
            e.ToTable("server_entries");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.HasIndex(x => x.CategoryId);
        });

        modelBuilder.Entity<ServerSettingEntity>(e =>
        {
            e.ToTable("server_settings");
            e.HasKey(x => x.Key);
        });

        ApplySnakeCaseColumnNames(modelBuilder);
    }

    private static void ApplySnakeCaseColumnNames(ModelBuilder modelBuilder)
    {
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entity.GetProperties())
            {
                property.SetColumnName(ToSnakeCase(property.Name));
            }
        }
    }

    private static string ToSnakeCase(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return value;
        }

        var builder = new StringBuilder(value.Length + 8);
        for (var i = 0; i < value.Length; i++)
        {
            var ch = value[i];
            if (char.IsUpper(ch))
            {
                if (i > 0 && builder[^1] != '_')
                {
                    builder.Append('_');
                }

                builder.Append(char.ToLowerInvariant(ch));
                continue;
            }

            builder.Append(ch);
        }

        return builder.ToString();
    }
}

public static class AvatarStarDatabase
{
    public static string ResolveDatabasePath(string? explicitPath = null)
    {
        var path = explicitPath;
        if (string.IsNullOrWhiteSpace(path))
        {
            path = Environment.GetEnvironmentVariable("AS_DB_PATH");
        }

        if (string.IsNullOrWhiteSpace(path))
        {
            path = Path.Combine(FindRepoRoot(), "data", "avatarstar.db");
        }

        return Path.GetFullPath(path);
    }

    public static string FindRepoRoot()
    {
        var envRoot = Environment.GetEnvironmentVariable("AS_REPO_ROOT");
        if (!string.IsNullOrWhiteSpace(envRoot) && Directory.Exists(envRoot))
        {
            return envRoot;
        }

        var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
        while (dir is not null)
        {
            if (Directory.Exists(Path.Combine(dir.FullName, "src")) &&
                (File.Exists(Path.Combine(dir.FullName, "AGENTS.md")) || Directory.Exists(Path.Combine(dir.FullName, ".git"))))
            {
                return dir.FullName;
            }

            dir = dir.Parent;
        }

        return Directory.GetCurrentDirectory();
    }
}

public sealed class DatabaseInitializer
{
    public void Initialize(string? dbPath = null, string? repoRoot = null)
    {
        var resolvedDbPath = AvatarStarDatabase.ResolveDatabasePath(dbPath);
        var dbDirectory = Path.GetDirectoryName(resolvedDbPath);
        if (!string.IsNullOrWhiteSpace(dbDirectory))
        {
            Directory.CreateDirectory(dbDirectory);
        }

        using var db = new AvatarStarDbContext(resolvedDbPath);
        db.Database.EnsureCreated();
        new DatabaseSchemaUpgrader().Upgrade(db);
        EnsureDefaultAccount(db);
        new SeedImporter(repoRoot ?? AvatarStarDatabase.FindRepoRoot()).Import(db);
        Log.Information("Database initialized: {DatabasePath}", resolvedDbPath);
    }

    private static void EnsureDefaultAccount(AvatarStarDbContext db)
    {
        if (db.Accounts.Any(x => x.Username == "test"))
        {
            return;
        }

        var (hash, salt) = PasswordHasher.HashPassword("test123");
        db.Accounts.Add(new AccountEntity
        {
            Username = "test",
            PasswordHash = hash,
            PasswordSalt = salt,
            PasswordAlgorithm = PasswordHasher.Algorithm,
            Status = 1,
            CreatedAt = DateTimeOffset.UtcNow.ToString("O")
        });
        db.SaveChanges();
    }
}

public sealed class DatabaseSchemaUpgrader
{
    public void Upgrade(AvatarStarDbContext db)
    {
        AddColumnIfMissing(db, "skill_definitions", "cool_down", "REAL NOT NULL DEFAULT 20");
        AddColumnIfMissing(db, "skill_definitions", "range", "REAL NOT NULL DEFAULT 8");

        Execute(db, """
CREATE TABLE IF NOT EXISTS online_reward_rules (
    prize_level INTEGER NOT NULL PRIMARY KEY,
    end_time_seconds INTEGER NOT NULL
)
""");
        Execute(db, """
CREATE TABLE IF NOT EXISTS online_reward_prizes (
    id INTEGER NOT NULL PRIMARY KEY,
    prize_level INTEGER NOT NULL,
    item_id TEXT NOT NULL,
    sid INTEGER NOT NULL,
    type INTEGER NOT NULL,
    sub_type INTEGER NOT NULL,
    grade INTEGER NOT NULL,
    resource TEXT NOT NULL,
    unit_type INTEGER NOT NULL,
    unit INTEGER NOT NULL,
    quantity INTEGER NOT NULL
)
""");
        Execute(db, "CREATE INDEX IF NOT EXISTS idx_online_reward_prizes_prize_level ON online_reward_prizes(prize_level)");

        Execute(db, """
CREATE TABLE IF NOT EXISTS character_online_reward_state (
    character_id INTEGER NOT NULL PRIMARY KEY,
    day_key TEXT NOT NULL,
    claimed_level INTEGER NOT NULL,
    stage_started_utc TEXT NOT NULL,
    updated_at TEXT NOT NULL
)
""");

        Execute(db, """
CREATE TABLE IF NOT EXISTS server_categories (
    id INTEGER NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL
)
""");
        Execute(db, """
CREATE TABLE IF NOT EXISTS server_entries (
    id INTEGER NOT NULL PRIMARY KEY,
    category_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    ip TEXT NOT NULL,
    port INTEGER NOT NULL,
    status INTEGER NOT NULL,
    sort_order INTEGER NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 1
)
""");
        Execute(db, "CREATE INDEX IF NOT EXISTS idx_server_entries_category_id ON server_entries(category_id)");

        Execute(db, """
CREATE TABLE IF NOT EXISTS server_settings (
    key TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    updated_at TEXT NOT NULL
)
""");
    }

    private static void AddColumnIfMissing(AvatarStarDbContext db, string table, string column, string definition)
    {
        var escapedTable = table.Replace("'", "''", StringComparison.Ordinal);
        var escapedColumn = column.Replace("'", "''", StringComparison.Ordinal);
        var exists = db.Database.SqlQueryRaw<int>(
                $"SELECT COUNT(1) AS Value FROM pragma_table_info('{escapedTable}') WHERE name = '{escapedColumn}'")
            .AsEnumerable()
            .FirstOrDefault() > 0;
        if (!exists)
        {
            Execute(db, $"ALTER TABLE {table} ADD COLUMN {column} {definition}");
        }
    }

    private static void Execute(AvatarStarDbContext db, string sql)
    {
        db.Database.ExecuteSqlRaw(sql);
    }
}

public static class PasswordHasher
{
    public const string Algorithm = "PBKDF2-SHA256";
    private const int Iterations = 100_000;

    public static (string Hash, string Salt) HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, Iterations, HashAlgorithmName.SHA256, 32);
        return (Convert.ToBase64String(hash), Convert.ToBase64String(salt));
    }

    public static bool Verify(string password, string hash, string salt)
    {
        var saltBytes = Convert.FromBase64String(salt);
        var expected = Convert.FromBase64String(hash);
        var actual = Rfc2898DeriveBytes.Pbkdf2(password, saltBytes, Iterations, HashAlgorithmName.SHA256, expected.Length);
        return CryptographicOperations.FixedTimeEquals(actual, expected);
    }
}

public sealed class AccountRepository
{
    private readonly string _dbPath;

    public AccountRepository(string? dbPath = null)
    {
        _dbPath = AvatarStarDatabase.ResolveDatabasePath(dbPath);
    }

    public string? LoginPassword(string username, string password)
    {
        using var db = new AvatarStarDbContext(_dbPath);
        var account = db.Accounts.FirstOrDefault(x => x.Username == username && x.Status == 1);
        if (account is null || !PasswordHasher.Verify(password, account.PasswordHash, account.PasswordSalt))
        {
            return null;
        }

        account.LastLoginAt = DateTimeOffset.UtcNow.ToString("O");
        var token = $"token_{username}_{Guid.NewGuid():N}";
        db.AuthSessions.Add(new AuthSessionEntity
        {
            Token = token,
            AccountId = account.Id,
            IssuedAt = DateTimeOffset.UtcNow.ToString("O")
        });
        db.SaveChanges();
        return token;
    }

    public long ValidateToken(string? token)
    {
        using var db = new AvatarStarDbContext(_dbPath);
        if (string.Equals(token, "AuthToken", StringComparison.Ordinal))
        {
            return EnsureDefaultAccount(db);
        }

        if (string.IsNullOrWhiteSpace(token))
        {
            return EnsureDefaultAccount(db);
        }

        var session = db.AuthSessions.FirstOrDefault(x => x.Token == token && x.RevokedAt == null);
        if (session is null)
        {
            return EnsureDefaultAccount(db);
        }

        session.LastUsedAt = DateTimeOffset.UtcNow.ToString("O");
        db.SaveChanges();
        return session.AccountId;
    }

    private static long EnsureDefaultAccount(AvatarStarDbContext db)
    {
        var account = db.Accounts.FirstOrDefault(x => x.Username == "test");
        if (account is not null)
        {
            return account.Id;
        }

        var (hash, salt) = PasswordHasher.HashPassword("test123");
        account = new AccountEntity
        {
            Username = "test",
            PasswordHash = hash,
            PasswordSalt = salt,
            PasswordAlgorithm = PasswordHasher.Algorithm,
            Status = 1,
            CreatedAt = DateTimeOffset.UtcNow.ToString("O")
        };
        db.Accounts.Add(account);
        db.SaveChanges();
        return account.Id;
    }
}

public sealed class ConfigRepository
{
    private readonly string _dbPath;

    public ConfigRepository(string? dbPath = null)
    {
        _dbPath = AvatarStarDatabase.ResolveDatabasePath(dbPath);
    }

    public string? GetConfigDocument(string key)
    {
        using var db = new AvatarStarDbContext(_dbPath);
        return db.ConfigDocuments.Find(key)?.JsonContent;
    }

    public IReadOnlyList<LobbyLevelEntity> GetLobbyLevels()
    {
        using var db = new AvatarStarDbContext(_dbPath);
        return db.LobbyLevels.Where(x => x.Enabled == 1).OrderBy(x => x.Id).ToArray();
    }

    public IReadOnlyDictionary<string, string> GetGameTexts()
    {
        using var db = new AvatarStarDbContext(_dbPath);
        return db.GameTexts.ToDictionary(x => x.TextId, x => x.Text, StringComparer.Ordinal);
    }

    public IReadOnlyList<ServerCategoryEntity> GetServerCategories()
    {
        using var db = new AvatarStarDbContext(_dbPath);
        return db.ServerCategories.OrderBy(x => x.SortOrder).ThenBy(x => x.Id).ToArray();
    }

    public IReadOnlyList<ServerEntryEntity> GetServerEntries()
    {
        using var db = new AvatarStarDbContext(_dbPath);
        return db.ServerEntries.Where(x => x.Enabled != 0).OrderBy(x => x.SortOrder).ThenBy(x => x.Id).ToArray();
    }

    public string? GetConfigDocumentBySuffix(string keySuffix)
    {
        using var db = new AvatarStarDbContext(_dbPath);
        return db.ConfigDocuments
            .Where(x => x.Key.EndsWith(keySuffix))
            .OrderBy(x => x.Key.Length)
            .Select(x => x.JsonContent)
            .FirstOrDefault();
    }

    public string? GetServerSetting(string key)
    {
        using var db = new AvatarStarDbContext(_dbPath);
        return db.ServerSettings.Find(key)?.Value;
    }
}

public sealed class SeedImporter
{
    private readonly string _repoRoot;
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public SeedImporter(string repoRoot)
    {
        _repoRoot = repoRoot;
    }

    public void Import(AvatarStarDbContext db)
    {
        ImportConfigDocuments(db);
        ImportGameTexts(db);
        ImportLobbyLevels(db);
        ImportShop(db);
        ImportBoxRules(db);
        ImportSkillDefinitions(db);
        ImportCheckinDefaults(db);
        ImportOnlineRewardDefaults(db);
        ImportServerListDefaults(db);
        ImportServerSettingsDefaults(db);
        db.SaveChanges();
    }

    private void ImportConfigDocuments(AvatarStarDbContext db)
    {
        var roots = new[]
        {
            Path.Combine(_repoRoot, "src", "AvatarStar.Server.Game", "Config"),
            Path.Combine(_repoRoot, "src", "AvatarStar.Server.Game", "Resources"),
            Path.Combine(_repoRoot, "tools", "resources")
        };

        foreach (var root in roots.Where(Directory.Exists))
        {
            foreach (var path in Directory.EnumerateFiles(root, "*.json", SearchOption.AllDirectories)
                         .Concat(Directory.EnumerateFiles(root, "*.lua", SearchOption.AllDirectories)))
            {
                var json = File.ReadAllText(path, Encoding.UTF8);
                UpsertConfigDocument(db, ToConfigDocumentKey(path), InferCategory(path), path, json);
            }
        }
    }

    private string ToConfigDocumentKey(string path)
    {
        return Path.GetRelativePath(_repoRoot, path).Replace('\\', '/');
    }

    private static string InferCategory(string path)
    {
        var normalized = path.Replace('\\', '/');
        if (normalized.Contains("/SysAvatarPayloads/", StringComparison.OrdinalIgnoreCase)) return "sysavatar_payload";
        if (normalized.Contains("/templates/", StringComparison.OrdinalIgnoreCase)) return "template";
        if (normalized.Contains("/character_customization/", StringComparison.OrdinalIgnoreCase)) return "character_customization";
        if (normalized.Contains("/tools/resources/", StringComparison.OrdinalIgnoreCase)) return "tool_resource";
        if (normalized.Contains("/Config/", StringComparison.OrdinalIgnoreCase)) return "config";
        return "resource";
    }

    private static void UpsertConfigDocument(AvatarStarDbContext db, string key, string category, string path, string json)
    {
        var hash = Sha256(json);
        var existing = db.ConfigDocuments.Find(key);
        if (existing is null)
        {
            db.ConfigDocuments.Add(new ConfigDocumentEntity
            {
                Key = key,
                Category = category,
                SourcePath = path,
                JsonContent = json,
                SourceHash = hash,
                UpdatedAt = DateTimeOffset.UtcNow.ToString("O")
            });
            return;
        }

        if (existing.SourceHash == hash)
        {
            return;
        }

        existing.Category = category;
        existing.SourcePath = path;
        existing.JsonContent = json;
        existing.SourceHash = hash;
        existing.UpdatedAt = DateTimeOffset.UtcNow.ToString("O");
    }

    private void ImportGameTexts(AvatarStarDbContext db)
    {
        var path = Path.Combine(_repoRoot, "src", "AvatarStar.Server.Game", "Config", "game_text_id_to_text.json");
        if (!File.Exists(path)) return;

        var json = File.ReadAllText(path, Encoding.UTF8);
        var hash = Sha256(json);
        var map = JsonSerializer.Deserialize<Dictionary<string, string>>(json, JsonOptions) ?? new();
        foreach (var (key, value) in map)
        {
            var existing = db.GameTexts.Find(key);
            if (existing is null)
            {
                db.GameTexts.Add(new GameTextEntity
                {
                    TextId = key,
                    Text = value,
                    SourceHash = hash,
                    UpdatedAt = DateTimeOffset.UtcNow.ToString("O")
                });
            }
            else if (existing.Text != value || existing.SourceHash != hash)
            {
                existing.Text = value;
                existing.SourceHash = hash;
                existing.UpdatedAt = DateTimeOffset.UtcNow.ToString("O");
            }
        }
    }

    private void ImportLobbyLevels(AvatarStarDbContext db)
    {
        var path = Path.Combine(_repoRoot, "src", "AvatarStar.Server.Game", "Config", "lobby_levelinfo.json");
        if (!File.Exists(path)) return;

        var map = JsonSerializer.Deserialize<Dictionary<string, string>>(File.ReadAllText(path, Encoding.UTF8), JsonOptions) ?? new();
        foreach (var (name, showName) in map)
        {
            if (!TryExtractLevelId(name, out var id)) continue;
            var existing = db.LobbyLevels.Find(id);
            if (existing is null)
            {
                db.LobbyLevels.Add(new LobbyLevelEntity
                {
                    Id = id,
                    Name = name,
                    GameType = 4,
                    ShowName = showName,
                    Description = showName,
                    Difficulty = 0,
                    Group = 0,
                    Enabled = 1
                });
            }
            else
            {
                existing.Name = name;
                existing.ShowName = showName;
                existing.Description = showName;
                existing.Enabled = 1;
            }
        }
    }

    private void ImportShop(AvatarStarDbContext db)
    {
        var path = Path.Combine(_repoRoot, "src", "AvatarStar.Server.Game", "Resources", "shop_config.json");
        if (!File.Exists(path)) return;

        var json = File.ReadAllText(path, Encoding.UTF8);
        var hash = Sha256(json);
        using var document = JsonDocument.Parse(json);
        foreach (var (categoryKey, item) in EnumerateShopItems(document.RootElement))
        {
            var sid = GetInt(item, "sid");
            if (sid <= 0) continue;
            var entity = db.ShopItems.Find(sid);
            if (entity is null)
            {
                entity = new ShopItemEntity { Sid = sid };
                db.ShopItems.Add(entity);
            }

            entity.Type = GetInt(item, "type");
            entity.Subtype = GetInt(item, "subtype");
            entity.Resource = GetString(item, "resource");
            entity.Display = GetString(item, "display");
            entity.Level = GetInt(item, "level");
            entity.Occupation = GetInt(item, "occupation", -1);
            entity.Grade = GetInt(item, "grade", 1);
            entity.Description = GetString(item, "description");
            entity.AvatarJson = TryRaw(item, "avatar");
            entity.AvatarLevel = TryNullableInt(item, "avatarLevel");
            entity.TipJson = TryRaw(item, "tip");
            entity.IsLimited = GetBoolInt(item, "isLimited");
            entity.Quantity = GetInt(item, "quantity", 1);
            entity.Category = FirstNonEmpty(GetString(item, "category"), categoryKey);
            entity.SourceHash = hash;
            entity.UpdatedAt = DateTimeOffset.UtcNow.ToString("O");

            if (item.TryGetProperty("prices", out var prices) && prices.ValueKind == JsonValueKind.Array)
            {
                foreach (var price in prices.EnumerateArray())
                {
                    var priceId = GetInt(price, "priceId", 1);
                    var priceEntity = db.ShopPrices.Find(sid, priceId);
                    if (priceEntity is null)
                    {
                        priceEntity = new ShopPriceEntity { Sid = sid, PriceId = priceId };
                        db.ShopPrices.Add(priceEntity);
                    }

                    priceEntity.Currency = GetInt(price, "currency");
                    priceEntity.Price = GetInt(price, "price");
                    priceEntity.RebatePrice = GetInt(price, "rebatePrice");
                    priceEntity.SellState = GetInt(price, "sellState");
                    priceEntity.UnitType = GetInt(price, "unitType", 1);
                    priceEntity.Unit = GetInt(price, "unit", 1);
                    priceEntity.RepeatDuration = GetInt(price, "repeatDuration", 1);
                    priceEntity.AccomplishCount = GetInt(price, "accomplishCount");
                    priceEntity.IsRenew = GetBoolInt(price, "isRenew");
                    priceEntity.IsCardPrice = GetBoolInt(price, "isCardPrice");
                    priceEntity.IsGive = GetBoolInt(price, "isGive");
                    priceEntity.VipLevel = GetInt(price, "vipLevel");
                    priceEntity.StartDateTime = GetLong(price, "startDateTime");
                    priceEntity.EndDateTime = GetLong(price, "endDateTime");
                }
            }
        }
    }

    private static IEnumerable<(string Category, JsonElement Item)> EnumerateShopItems(JsonElement root)
    {
        if (root.TryGetProperty("items", out var directItems) && directItems.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in directItems.EnumerateArray())
            {
                yield return (string.Empty, item);
            }

            yield break;
        }

        if (!root.TryGetProperty("shop", out var shop) ||
            !shop.TryGetProperty("categories", out var categories) ||
            categories.ValueKind != JsonValueKind.Object)
        {
            yield break;
        }

        foreach (var category in categories.EnumerateObject())
        {
            if (!category.Value.TryGetProperty("items", out var items) || items.ValueKind != JsonValueKind.Array)
            {
                continue;
            }

            foreach (var item in items.EnumerateArray())
            {
                yield return (category.Name, item);
            }
        }
    }

    private void ImportBoxRules(AvatarStarDbContext db)
    {
        var path = Path.Combine(_repoRoot, "src", "AvatarStar.Server.Game", "Resources", "box_rules.json");
        if (!File.Exists(path)) return;

        using var doc = JsonDocument.Parse(File.ReadAllText(path, Encoding.UTF8));
        if (!doc.RootElement.TryGetProperty("categories", out var categories) || categories.ValueKind != JsonValueKind.Array)
        {
            return;
        }

        foreach (var category in categories.EnumerateArray())
        {
            var categoryId = GetInt(category, "category");
            if (categoryId <= 0) continue;
            var entity = db.BoxCategories.Find(categoryId);
            if (entity is null)
            {
                entity = new BoxCategoryEntity { Category = categoryId };
                db.BoxCategories.Add(entity);
            }

            entity.MainCategory = GetInt(category, "mainCategory");
            entity.BoxResource = GetString(category, "boxResource");
            entity.KeyResource = GetString(category, "keyResource");
            entity.BoxName = GetString(category, "boxName");
            entity.KeyName = GetString(category, "keyName");
            entity.Price = GetInt(category, "price");

            if (category.TryGetProperty("pointList", out var pointList) && pointList.ValueKind == JsonValueKind.Array)
            {
                foreach (var point in pointList.EnumerateArray())
                {
                    var gift = GetInt(point, "category");
                    if (gift <= 0) continue;
                    var pointEntity = db.BoxPointRules.Find(categoryId, gift);
                    if (pointEntity is null)
                    {
                        pointEntity = new BoxPointRuleEntity { BoxCategory = categoryId, GiftCategory = gift };
                        db.BoxPointRules.Add(pointEntity);
                    }

                    pointEntity.Unit = GetInt(point, "unit");
                }
            }

            ImportBoxPrizePool(db, categoryId, "display", category, "prizeList");
            ImportBoxPrizePool(db, categoryId, "open", category, "openPool");
        }
    }

    private static void ImportBoxPrizePool(AvatarStarDbContext db, int categoryId, string poolType, JsonElement category, string property)
    {
        if (!category.TryGetProperty(property, out var pool) || pool.ValueKind != JsonValueKind.Array)
        {
            return;
        }

        var index = 0;
        foreach (var prize in pool.EnumerateArray())
        {
            index++;
            var id = categoryId * 100_000 + (poolType == "open" ? 50_000 : 0) + index;
            var entity = db.BoxPrizes.Find(id);
            if (entity is null)
            {
                entity = new BoxPrizeEntity { Id = id };
                db.BoxPrizes.Add(entity);
            }

            entity.Category = categoryId;
            entity.PoolType = poolType;
            entity.PrizeId = GetInt(prize, "prizeId");
            entity.Sid = GetInt(prize, "sid");
            entity.Type = GetInt(prize, "type");
            entity.SubType = GetInt(prize, "subType");
            entity.Grade = GetInt(prize, "grade", 1);
            entity.Resource = GetString(prize, "resource");
            entity.UnitType = GetInt(prize, "unitType", 1);
            entity.Unit = GetInt(prize, "unit", 1);
            entity.Quantity = GetInt(prize, "quantity", 1);
            entity.Weight = GetInt(prize, "weight", 1);
        }
    }

    private static void ImportSkillDefinitions(AvatarStarDbContext db)
    {
        static SkillDefinitionEntity Skill(int id, int occupation, string resource, string displayBase, int isActive)
        {
            return new SkillDefinitionEntity
            {
                Id = id,
                Occupation = occupation,
                Resource = resource,
                DisplayBase = displayBase,
                IsActive = isActive,
                CoolDown = isActive != 0 ? 20f : 0f,
                Range = isActive != 0 ? 8f : 0f
            };
        }

        var skills = new[]
        {
            Skill(0, 0, "cure", "id_datalist_Battlefield_Heal_01", 1),
            Skill(3, 0, "shock", "id_datalist_Shockwave_01", 1),
            Skill(6, 0, "vitals", "id_datalist_Achilles_Heel_01", 0),
            Skill(9, 0, "rain", "id_datalist_Arrow_Shower_01", 1),
            Skill(14, 0, "energy", "id_datalist_Healing_Beacon_01", 1),
            Skill(76, 0, "feud", "tips_buff_langwangshichou", 0),
            Skill(1, 1, "shield", "id_datalist_Shield_01", 1),
            Skill(4, 1, "gallop", "id_datalist_Haste_01", 1),
            Skill(7, 1, "tenacity", "id_datalist_Perseverance_01", 0),
            Skill(10, 1, "heavy", "id_datalist_Blitzkrieg_01", 0),
            Skill(12, 1, "transfer", "id_datalist_Damage_Converter_01", 0),
            Skill(2, 2, "latent", "id_datalist_Stealth_01", 1),
            Skill(5, 2, "piercing", "id_datalist_Fatal_Shot_01", 0),
            Skill(8, 2, "poison", "id_datalist_Poison_Pierce_01", 0),
            Skill(11, 2, "spurt", "id_datalist_Deadly_Sprint_01", 1),
            Skill(13, 2, "snare", "id_datalist_Trap_01", 1),
            Skill(38, 3, "conduction", "id_datalist_shengmingchuandao_01", 1),
            Skill(39, 3, "suckblood", "id_datalist_shengmingchouqu_01", 0),
            Skill(40, 3, "plague", "id_datalist_wenyichuanbo_01", 0),
            Skill(41, 3, "gasbomb", "id_datalist_duqidan_01", 0),
            Skill(42, 3, "overreaction", "id_datalist_guojifanying_01", 1)
        };

        foreach (var skill in skills)
        {
            var existing = db.SkillDefinitions.Find(skill.Id);
            if (existing is null)
            {
                db.SkillDefinitions.Add(skill);
            }
            else
            {
                existing.Occupation = skill.Occupation;
                existing.Resource = skill.Resource;
                existing.DisplayBase = skill.DisplayBase;
                existing.IsActive = skill.IsActive;
                existing.CoolDown = skill.CoolDown;
                existing.Range = skill.Range;
            }
        }
    }

    private static void ImportCheckinDefaults(AvatarStarDbContext db)
    {
        var config = db.CheckinConfig.Find(1);
        if (config is null)
        {
            db.CheckinConfig.Add(new CheckinConfigEntity { Id = 1, SupplementCurrency = 4, SupplementPrice = 1 });
        }

        static CheckinRewardEntity Reward(
            int id,
            int entryId,
            string itemId,
            int type,
            int subType,
            int grade,
            string resource,
            int unitType,
            int unit,
            int quantity,
            int sid = 0)
        {
            return new CheckinRewardEntity
            {
                Id = id,
                CheckinEntryId = entryId,
                ItemId = itemId,
                Sid = sid,
                Type = type,
                SubType = subType,
                Grade = grade,
                Resource = resource,
                UnitType = unitType,
                Unit = unit,
                Quantity = quantity
            };
        }

        static CheckinEntryEntity Entry(int id, string name, int type)
        {
            return new CheckinEntryEntity
            {
                Id = id,
                Name = name,
                Type = type,
                PlayerLevel = 0
            };
        }

        var entries = new[]
        {
            Entry(5, "1", 1),
            Entry(1, "2", 2),
            Entry(2, "4", 2),
            Entry(3, "7", 2),
            Entry(4, "11", 2),
            Entry(6, "16", 2),
            Entry(7, "22", 2)
        };

        foreach (var entry in entries)
        {
            var existing = db.CheckinEntries.Find(entry.Id);
            if (existing is null)
            {
                db.CheckinEntries.Add(entry);
            }
            else
            {
                existing.Name = entry.Name;
                existing.Type = entry.Type;
                existing.PlayerLevel = entry.PlayerLevel;
            }
        }

        var rewards = new[]
        {
            Reward(1, 5, "91", 3, 0, 3, "leechdom_cardiac", 3, 2, 2),
            Reward(2, 5, "90", 3, 0, 2, "bandage_02", 3, 2, 2),
            Reward(26, 1, "90", 3, 0, 2, "bandage_02", 3, 2, 2),
            Reward(44, 1, "113", 3, 0, 3, "intensify_luck", 3, 1, 1),
            Reward(27, 2, "90", 3, 0, 2, "bandage_02", 3, 4, 4),
            Reward(28, 2, "113", 3, 0, 3, "intensify_luck", 3, 1, 1),
            Reward(45, 2, "207", 3, 0, 1, "yaoshi_tong", 3, 4, 4),
            Reward(29, 3, "91", 3, 0, 3, "leechdom_cardiac", 3, 5, 5),
            Reward(30, 3, "113", 3, 0, 3, "intensify_luck", 3, 1, 1),
            Reward(31, 3, "207", 3, 0, 1, "yaoshi_tong", 3, 5, 5),
            Reward(60, 3, "814", 2, 4, 5, "shotgun_21", 4, 604800, 1),
            Reward(61, 3, "61", 3, 0, 3, "gem_red03", 3, 1, 1),
            Reward(32, 4, "91", 3, 0, 3, "leechdom_cardiac", 3, 5, 5),
            Reward(33, 4, "113", 3, 0, 3, "intensify_luck", 3, 1, 1),
            Reward(34, 4, "212", 3, 0, 1, "yaoshi_yin", 3, 5, 5),
            Reward(35, 4, "343", 3, 0, 1, "avatar_design01", 3, 10, 10),
            Reward(62, 4, "815", 2, 5, 5, "pistol_21", 4, 604800, 1),
            Reward(63, 4, "62", 3, 0, 3, "gem_yellow03", 3, 1, 1),
            Reward(36, 6, "96", 3, 0, 4, "food_lobster", 3, 5, 5),
            Reward(37, 6, "113", 3, 0, 3, "intensify_luck", 3, 2, 2),
            Reward(38, 6, "212", 3, 0, 1, "yaoshi_yin", 3, 6, 6),
            Reward(39, 6, "343", 3, 0, 1, "avatar_design01", 3, 10, 10),
            Reward(64, 6, "819", 2, 11, 5, "rpg_21", 4, 604800, 1),
            Reward(65, 6, "63", 3, 0, 3, "gem_green03", 3, 1, 1),
            Reward(40, 7, "96", 3, 0, 4, "food_lobster", 3, 5, 5),
            Reward(41, 7, "113", 3, 0, 3, "intensify_luck", 3, 3, 3),
            Reward(43, 7, "343", 3, 0, 1, "avatar_design01", 3, 10, 10),
            Reward(59, 7, "212", 3, 0, 1, "yaoshi_yin", 3, 8, 8),
            Reward(66, 7, "1154", 2, 15, 5, "sprayer_21", 4, 604800, 1),
            Reward(67, 7, "64", 3, 0, 3, "gem_blue03", 3, 1, 1)
        };

        foreach (var reward in rewards)
        {
            var existing = db.CheckinRewards.Find(reward.Id);
            if (existing is null)
            {
                db.CheckinRewards.Add(reward);
            }
            else
            {
                existing.CheckinEntryId = reward.CheckinEntryId;
                existing.Sid = reward.Sid;
                existing.ItemId = reward.ItemId;
                existing.Type = reward.Type;
                existing.SubType = reward.SubType;
                existing.Grade = reward.Grade;
                existing.Resource = reward.Resource;
                existing.UnitType = reward.UnitType;
                existing.Unit = reward.Unit;
                existing.Quantity = reward.Quantity;
            }
        }
    }

    private static void ImportOnlineRewardDefaults(AvatarStarDbContext db)
    {
        static OnlineRewardPrizeEntity Prize(
            int id,
            int prizeLevel,
            string itemId,
            int type,
            int subType,
            int quantity,
            int grade,
            int unitType,
            string resource,
            int sid = 0,
            int unit = 0)
        {
            return new OnlineRewardPrizeEntity
            {
                Id = id,
                PrizeLevel = prizeLevel,
                ItemId = itemId,
                Sid = sid,
                Type = type,
                SubType = subType,
                Grade = grade,
                Resource = resource,
                UnitType = unitType,
                Unit = unit <= 0 ? quantity : unit,
                Quantity = quantity
            };
        }

        var levels = new[]
        {
            new OnlineRewardRuleEntity { PrizeLevel = 1, EndTimeSeconds = 60 },
            new OnlineRewardRuleEntity { PrizeLevel = 2, EndTimeSeconds = 120 },
            new OnlineRewardRuleEntity { PrizeLevel = 3, EndTimeSeconds = 180 }
        };

        foreach (var level in levels)
        {
            var existing = db.OnlineRewardRules.Find(level.PrizeLevel);
            if (existing is null)
            {
                db.OnlineRewardRules.Add(level);
            }
            else
            {
                existing.EndTimeSeconds = level.EndTimeSeconds;
            }
        }

        var prizes = new[]
        {
            Prize(101, 1, "548", 2, 102, 7200, 3, 4, "'wing15_indie','wing15','wing15'", 20054, 7200),
            Prize(102, 1, "488", 3, 103, 7, 4, 3, "gift_sweet", 488),
            Prize(103, 1, "275", 3, 100, 2, 2, 3, "loudspeaker", 20597),
            Prize(201, 2, "1", 7, 0, 1000, 1, 0, string.Empty),
            Prize(202, 2, "1379", 3, 304, 3, 5, 3, "piece_wing40", 20717),
            Prize(203, 2, "93", 3, 102, 5, 3, 3, "leechdom_first_aid_kit", 20723),
            Prize(301, 3, "637", 3, 110, 1, 3, 3, "ticket_complementarity", 637),
            Prize(302, 3, "1", 7, 0, 2000, 1, 0, string.Empty),
            Prize(303, 3, "92", 3, 102, 5, 2, 3, "leechdom_blood_serum", 20721)
        };

        foreach (var prize in prizes)
        {
            var existing = db.OnlineRewardPrizes.Find(prize.Id);
            if (existing is null)
            {
                db.OnlineRewardPrizes.Add(prize);
            }
            else
            {
                existing.PrizeLevel = prize.PrizeLevel;
                existing.ItemId = prize.ItemId;
                existing.Sid = prize.Sid;
                existing.Type = prize.Type;
                existing.SubType = prize.SubType;
                existing.Grade = prize.Grade;
                existing.Resource = prize.Resource;
                existing.UnitType = prize.UnitType;
                existing.Unit = prize.Unit;
                existing.Quantity = prize.Quantity;
            }
        }
    }

    private static void ImportServerListDefaults(AvatarStarDbContext db)
    {
        var categories = new[]
        {
            new ServerCategoryEntity { Id = 1, Name = "Category", SortOrder = 1 },
            new ServerCategoryEntity { Id = 2, Name = "Category 2", SortOrder = 2 }
        };

        foreach (var category in categories)
        {
            var existing = db.ServerCategories.Find(category.Id);
            if (existing is null)
            {
                db.ServerCategories.Add(category);
            }
            else
            {
                existing.Name = category.Name;
                existing.SortOrder = category.SortOrder;
            }
        }

        var servers = new[]
        {
            new ServerEntryEntity { Id = 1, CategoryId = 1, Name = "Server 1", Ip = "127.0.0.1", Port = 1234, Status = 0, SortOrder = 1, Enabled = 1 },
            new ServerEntryEntity { Id = 2, CategoryId = 1, Name = "Server 2", Ip = "127.0.0.1", Port = 1234, Status = 51, SortOrder = 2, Enabled = 1 },
            new ServerEntryEntity { Id = 3, CategoryId = 1, Name = "Server 3", Ip = "127.0.0.1", Port = 1234, Status = 81, SortOrder = 3, Enabled = 1 },
            new ServerEntryEntity { Id = 4, CategoryId = 1, Name = "Server 4", Ip = "127.0.0.1", Port = 1234, Status = 255, SortOrder = 4, Enabled = 1 },
            new ServerEntryEntity { Id = 5, CategoryId = 2, Name = "Server 5", Ip = "127.0.0.1", Port = 1234, Status = 0, SortOrder = 1, Enabled = 1 },
            new ServerEntryEntity { Id = 6, CategoryId = 2, Name = "Server 6", Ip = "127.0.0.1", Port = 1234, Status = 51, SortOrder = 2, Enabled = 1 }
        };

        foreach (var server in servers)
        {
            var existing = db.ServerEntries.Find(server.Id);
            if (existing is null)
            {
                db.ServerEntries.Add(server);
            }
            else
            {
                existing.CategoryId = server.CategoryId;
                existing.Name = server.Name;
                existing.Ip = server.Ip;
                existing.Port = server.Port;
                existing.Status = server.Status;
                existing.SortOrder = server.SortOrder;
                existing.Enabled = server.Enabled;
            }
        }
    }

    private static void ImportServerSettingsDefaults(AvatarStarDbContext db)
    {
        UpsertServerSetting(db, "practice.random_map.enabled", "1", "practice", "Enable DB-backed random map choices for practice rooms.");
        UpsertServerSetting(db, "debug.generic_ok_for_known_rpc", "1", "debug", "Return generic ok for known but not fully modeled RPCs.");
    }

    private static void UpsertServerSetting(AvatarStarDbContext db, string key, string value, string category, string description)
    {
        var existing = db.ServerSettings.Find(key);
        if (existing is null)
        {
            db.ServerSettings.Add(new ServerSettingEntity
            {
                Key = key,
                Value = value,
                Category = category,
                Description = description,
                UpdatedAt = DateTimeOffset.UtcNow.ToString("O")
            });
            return;
        }

        if (!string.Equals(existing.Value, value, StringComparison.Ordinal) ||
            !string.Equals(existing.Category, category, StringComparison.Ordinal) ||
            !string.Equals(existing.Description, description, StringComparison.Ordinal))
        {
            existing.Value = value;
            existing.Category = category;
            existing.Description = description;
            existing.UpdatedAt = DateTimeOffset.UtcNow.ToString("O");
        }
    }

    private static bool TryExtractLevelId(string key, out long id)
    {
        var digits = new string(key.Where(char.IsDigit).ToArray());
        return long.TryParse(digits, out id);
    }

    private static int GetInt(JsonElement element, string property, int fallback = 0)
    {
        return element.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var parsed)
            ? parsed
            : fallback;
    }

    private static int? TryNullableInt(JsonElement element, string property)
    {
        return element.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var parsed)
            ? parsed
            : null;
    }

    private static long GetLong(JsonElement element, string property)
    {
        return element.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.Number && value.TryGetInt64(out var parsed)
            ? parsed
            : 0;
    }

    private static string GetString(JsonElement element, string property)
    {
        return element.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString() ?? string.Empty
            : string.Empty;
    }

    private static int GetBoolInt(JsonElement element, string property)
    {
        if (!element.TryGetProperty(property, out var value)) return 0;
        return value.ValueKind switch
        {
            JsonValueKind.True => 1,
            JsonValueKind.False => 0,
            JsonValueKind.Number => value.TryGetInt32(out var parsed) ? parsed : 0,
            _ => 0
        };
    }

    private static string? TryRaw(JsonElement element, string property)
    {
        return element.TryGetProperty(property, out var value) && value.ValueKind is not JsonValueKind.Null and not JsonValueKind.Undefined
            ? value.GetRawText()
            : null;
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value;
            }
        }

        return string.Empty;
    }

    private static string Sha256(string input)
    {
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(input)));
    }
}

public sealed class AccountEntity
{
    public long Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string PasswordSalt { get; set; } = string.Empty;
    public string PasswordAlgorithm { get; set; } = string.Empty;
    public int Status { get; set; } = 1;
    public string CreatedAt { get; set; } = string.Empty;
    public string? LastLoginAt { get; set; }
}

public sealed class AuthSessionEntity
{
    public string Token { get; set; } = string.Empty;
    public long AccountId { get; set; }
    public string IssuedAt { get; set; } = string.Empty;
    public string? ExpiresAt { get; set; }
    public string? LastUsedAt { get; set; }
    public string? RevokedAt { get; set; }
}

public sealed class CharacterEntity
{
    public int Id { get; set; }
    public long AccountId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Level { get; set; } = 1;
    public int Occupation { get; set; }
    public string BattleForce { get; set; } = "0";
    public int MaxHealth { get; set; } = 2300;
    public int Gp { get; set; } = 100000;
    public int Mb { get; set; }
    public int Tb { get; set; }
    public int NextPid { get; set; } = 1;
    public string EquipAvatarJson { get; set; } = "{}";
    public string? EquippedAvatarPid { get; set; }
    public string CreatedAt { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
    public string? DeletedAt { get; set; }
}

public sealed class InventoryItemEntity
{
    public long Id { get; set; }
    public int CharacterId { get; set; }
    public string Pid { get; set; } = string.Empty;
    public int StorageType { get; set; }
    public int Slot { get; set; }
    public int Sid { get; set; }
    public int Type { get; set; }
    public int Subtype { get; set; }
    public int SubType { get; set; }
    public string Resource { get; set; } = string.Empty;
    public string Display { get; set; } = string.Empty;
    public string Designer { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Grade { get; set; }
    public int Quantity { get; set; }
    public int UnitType { get; set; }
    public int Unit { get; set; }
    public int Remain { get; set; }
    public int IsRenew { get; set; }
    public int Category { get; set; }
    public string IsBind { get; set; } = "N";
    public string IsEquip { get; set; } = "N";
    public string? AvatarJson { get; set; }
    public int? Position { get; set; }
    public string? AttributesJson { get; set; }
    public string CreatedAt { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
}

public sealed class EquippedItemEntity
{
    public int CharacterId { get; set; }
    public int EquipType { get; set; }
    public string Pid { get; set; } = string.Empty;
}

public sealed class HotkeySlotEntity
{
    public int CharacterId { get; set; }
    public int Slot { get; set; }
    public int EntryType { get; set; }
    public string ItemId { get; set; } = string.Empty;
    public string Resource { get; set; } = string.Empty;
    public string Display { get; set; } = string.Empty;
    public int Grade { get; set; }
    public int Quantity { get; set; }
    public int UnitType { get; set; }
    public int Unit { get; set; }
    public int Subtype { get; set; }
    public int Sid { get; set; }
    public int Level { get; set; }
}

public sealed class CharacterSkillLevelEntity
{
    public int CharacterId { get; set; }
    public int SkillId { get; set; }
    public int Level { get; set; }
}

public sealed class SkillDefinitionEntity
{
    public int Id { get; set; }
    public int Occupation { get; set; }
    public string Resource { get; set; } = string.Empty;
    public string DisplayBase { get; set; } = string.Empty;
    public int IsActive { get; set; }
    public float CoolDown { get; set; } = 20f;
    public float Range { get; set; } = 8f;
}

public sealed class OnlineRewardRuleEntity
{
    public int PrizeLevel { get; set; }
    public int EndTimeSeconds { get; set; }
}

public sealed class OnlineRewardPrizeEntity
{
    public int Id { get; set; }
    public int PrizeLevel { get; set; }
    public string ItemId { get; set; } = string.Empty;
    public int Sid { get; set; }
    public int Type { get; set; }
    public int SubType { get; set; }
    public int Grade { get; set; }
    public string Resource { get; set; } = string.Empty;
    public int UnitType { get; set; }
    public int Unit { get; set; }
    public int Quantity { get; set; }
}

public sealed class CharacterOnlineRewardStateEntity
{
    public int CharacterId { get; set; }
    public string DayKey { get; set; } = string.Empty;
    public int ClaimedLevel { get; set; }
    public string StageStartedUtc { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
}

public sealed class CheckinConfigEntity
{
    public int Id { get; set; } = 1;
    public int SupplementCurrency { get; set; }
    public int SupplementPrice { get; set; }
}

public sealed class CheckinEntryEntity
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Type { get; set; }
    public int PlayerLevel { get; set; }
}

public sealed class CheckinRewardEntity
{
    public int Id { get; set; }
    public int CheckinEntryId { get; set; }
    public int Sid { get; set; }
    public string ItemId { get; set; } = string.Empty;
    public int Type { get; set; }
    public int SubType { get; set; }
    public int Grade { get; set; }
    public string Resource { get; set; } = string.Empty;
    public int UnitType { get; set; }
    public int Unit { get; set; }
    public int Quantity { get; set; }
}

public sealed class CharacterCheckinDayEntity
{
    public int CharacterId { get; set; }
    public string MonthKey { get; set; } = string.Empty;
    public int Day { get; set; }
    public int IsSupplement { get; set; }
    public string CheckedAt { get; set; } = string.Empty;
}

public sealed class CharacterCheckinClaimEntity
{
    public int CharacterId { get; set; }
    public string MonthKey { get; set; } = string.Empty;
    public int CheckinId { get; set; }
    public string ClaimedAt { get; set; } = string.Empty;
}

public sealed class BoxCategoryEntity
{
    public int Category { get; set; }
    public int MainCategory { get; set; }
    public string BoxResource { get; set; } = string.Empty;
    public string KeyResource { get; set; } = string.Empty;
    public string BoxName { get; set; } = string.Empty;
    public string KeyName { get; set; } = string.Empty;
    public int Price { get; set; }
}

public sealed class BoxPointRuleEntity
{
    public int BoxCategory { get; set; }
    public int GiftCategory { get; set; }
    public int Unit { get; set; }
}

public sealed class BoxPrizeEntity
{
    public int Id { get; set; }
    public int Category { get; set; }
    public string PoolType { get; set; } = string.Empty;
    public int PrizeId { get; set; }
    public int Sid { get; set; }
    public int Type { get; set; }
    public int SubType { get; set; }
    public int Grade { get; set; }
    public string Resource { get; set; } = string.Empty;
    public int UnitType { get; set; }
    public int Unit { get; set; }
    public int Quantity { get; set; }
    public int Weight { get; set; }
}

public sealed class CharacterBoxPointEntity
{
    public int CharacterId { get; set; }
    public int Category { get; set; }
    public int Points { get; set; }
}

public sealed class CharacterBoxPointClaimEntity
{
    public int CharacterId { get; set; }
    public int Category { get; set; }
    public int Threshold { get; set; }
    public int ClaimCount { get; set; }
}

public sealed class ShopItemEntity
{
    public int Sid { get; set; }
    public int Type { get; set; }
    public int Subtype { get; set; }
    public string Resource { get; set; } = string.Empty;
    public string Display { get; set; } = string.Empty;
    public int Level { get; set; }
    public int Occupation { get; set; }
    public int Grade { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? AvatarJson { get; set; }
    public int? AvatarLevel { get; set; }
    public string? TipJson { get; set; }
    public int IsLimited { get; set; }
    public int Quantity { get; set; }
    public string Category { get; set; } = string.Empty;
    public string SourceHash { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
}

public sealed class ShopPriceEntity
{
    public int Sid { get; set; }
    public int PriceId { get; set; }
    public int Currency { get; set; }
    public int Price { get; set; }
    public int RebatePrice { get; set; }
    public int SellState { get; set; }
    public int UnitType { get; set; }
    public int Unit { get; set; }
    public int RepeatDuration { get; set; }
    public int AccomplishCount { get; set; }
    public int IsRenew { get; set; }
    public int IsCardPrice { get; set; }
    public int IsGive { get; set; }
    public int VipLevel { get; set; }
    public long StartDateTime { get; set; }
    public long EndDateTime { get; set; }
}

public sealed class CharacterShopPurchaseEntity
{
    public int CharacterId { get; set; }
    public int Sid { get; set; }
    public int PriceId { get; set; }
    public int PurchaseCount { get; set; }
    public string UpdatedAt { get; set; } = string.Empty;
}

public sealed class GameTextEntity
{
    public string TextId { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
    public string SourceHash { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
}

public sealed class LobbyLevelEntity
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int GameType { get; set; }
    public string ShowName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Difficulty { get; set; }
    public int Group { get; set; }
    public int Enabled { get; set; } = 1;
}

public sealed class ConfigDocumentEntity
{
    public string Key { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string SourcePath { get; set; } = string.Empty;
    public string JsonContent { get; set; } = string.Empty;
    public string SourceHash { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
}

public sealed class ServerCategoryEntity
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

public sealed class ServerEntryEntity
{
    public int Id { get; set; }
    public int CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Ip { get; set; } = string.Empty;
    public int Port { get; set; }
    public int Status { get; set; }
    public int SortOrder { get; set; }
    public int Enabled { get; set; } = 1;
}

public sealed class ServerSettingEntity
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
}
