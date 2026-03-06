namespace BirthChain.Application.Interfaces;

public interface IEmailService
{
    Task SendOtpAsync(string toEmail, string code, string purpose);

    /// <summary>Welcome email sent after email verification — includes QR code ID and patient info.</summary>
    Task SendWelcomeEmailAsync(string toEmail, string fullName, string qrCodeId);

    /// <summary>Notification sent to patient when a new medical record is added.</summary>
    Task SendRecordAddedEmailAsync(string toEmail, string patientName, string qrCodeId, string providerName, string facility, string description, DateTime recordDate);

    /// <summary>Confirmation email after password was successfully reset.</summary>
    Task SendPasswordResetConfirmationAsync(string toEmail, string fullName);

    /// <summary>Notification sent when a provider is added to a facility.</summary>
    Task SendProviderWelcomeEmailAsync(string toEmail, string fullName, string facilityName, string specialty);
}
