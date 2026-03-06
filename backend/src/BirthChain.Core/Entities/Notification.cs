namespace BirthChain.Core.Entities;

/// <summary>
/// Stored notification for in-app notification history.
/// </summary>
public class Notification : BaseEntity
{
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public bool IsRead { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? Data { get; set; } // Optional JSON data
}
