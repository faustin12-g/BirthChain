namespace BirthChain.Core.Entities;

/// <summary>
/// Core business record linking a client to a provider.
/// Append-only — no updates or deletes.
/// </summary>
public class Record : BaseEntity
{
    public Guid ClientId { get; set; }
    public Guid ProviderId { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
