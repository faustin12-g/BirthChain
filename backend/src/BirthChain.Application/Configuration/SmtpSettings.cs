namespace BirthChain.Application.Configuration;

public class SmtpSettings
{
    public const string SectionName = "Smtp";

    public string Host { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string DisplayName { get; set; } = "BirthChain";

    /// <summary>
    /// Resend API key for HTTP-based email sending (works on cloud platforms like Railway)
    /// </summary>
    public string ResendApiKey { get; set; } = string.Empty;

    /// <summary>
    /// Use Resend API instead of SMTP (required for Railway/Render/Heroku)
    /// </summary>
    public bool UseResend { get; set; } = false;
}
