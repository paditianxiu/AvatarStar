namespace AvatarStar.Server.Database;

public sealed record AuthTokenRecord(long AccountId, string Username, DateTime ExpiresAtUtc);
