namespace BirthChain.Core.Entities;

/// <summary>
/// Authentication user. Supports Admin, FacilityAdmin, Provider, and Patient roles.
/// </summary>
public class User : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "Provider"; // "Admin", "FacilityAdmin", "Provider", or "Patient"
    public bool IsActive { get; set; } = true;
    public bool IsEmailVerified { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Links FacilityAdmin users to their facility. Null for Admin/Patient.
    /// </summary>
    public Guid? FacilityId { get; set; }
}
