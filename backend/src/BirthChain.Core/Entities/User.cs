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
    public string? ProfileImageUrl { get; set; }
    public string? Phone { get; set; }
    public string? FcmToken { get; set; } // Firebase Cloud Messaging token for push notifications

    /// <summary>
    /// Links FacilityAdmin users to their facility. Null for Admin/Patient.
    /// </summary>
    public Guid? FacilityId { get; set; }

    // PIN-based security for patient data access
    /// <summary>Hashed 4-6 digit PIN for secure data access</summary>
    public string? PinHash { get; set; }

    /// <summary>Number of consecutive failed PIN attempts</summary>
    public int PinFailedAttempts { get; set; } = 0;

    /// <summary>When the PIN lockout ends (null if not locked)</summary>
    public DateTime? PinLockoutEnd { get; set; }
}
