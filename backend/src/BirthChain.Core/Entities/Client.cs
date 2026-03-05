namespace BirthChain.Core.Entities;

/// <summary>
/// Client / Patient registered by a provider.
/// </summary>
public class Client : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public string QrCodeId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
