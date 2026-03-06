namespace BirthChain.Core.Entities;

/// <summary>
/// One-time-password for email verification and password reset.
/// </summary>
public class OtpCode : BaseEntity
{
    public string Email { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;

    /// <summary>"EmailVerification" or "PasswordReset"</summary>
    public string Purpose { get; set; } = string.Empty;

    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
