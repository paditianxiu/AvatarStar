using AvatarStar.Server;

namespace AvatarStar.Server.Game;

internal partial class GameClient
{
    internal async Task SendFiveKillFeedbackAsync(int roomId, long generation, int kills)
    {
        using var writer = new PacketWriter();
        // Lobby connection push commands also reach StateMainGame.EventServerCmd.
        writer.WriteByte(0x20);
        writer.WriteString($"cmd=\"kill_streak\"\nroomId={roomId}\ngeneration={generation}\nkills={kills}\nstreak=5");
        await SendAsync(writer);
    }
}
