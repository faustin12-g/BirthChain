namespace BirthChain.Core.Entities;

/// <summary>
/// Audit / Activity log. Judges LOVE this.
/// Tracks every significant action in the system.
/// </summary>
public class ActivityLog : BaseEntity
{
    public Guid UserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
