namespace BirthChain.Core.Entities;

/// <summary>
/// Client / Patient — can be registered by a provider or self-registered.
/// </summary>
public class Client : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Gender { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public string QrCodeId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Nullable — set when a patient creates their own account.</summary>
    public Guid? UserId { get; set; }
}
