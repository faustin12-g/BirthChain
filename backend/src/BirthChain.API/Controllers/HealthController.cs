using BirthChain.Application.Configuration;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace BirthChain.API.Controllers;

/// <summary>
/// Health-check endpoint to verify the API is running.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly IEmailService _emailService;
    private readonly SmtpSettings _smtpSettings;

    public HealthController(IEmailService emailService, IOptions<SmtpSettings> smtpOptions)
    {
        _emailService = emailService;
        _smtpSettings = smtpOptions.Value;
    }

    [HttpGet]
    public IActionResult Get() => Ok(new { status = "healthy", service = "BirthChain API" });

    /// <summary>
    /// Check email configuration
    /// </summary>
    [HttpGet("email-config")]
    public IActionResult GetEmailConfig()
    {
        return Ok(new
        {
            useResend = _smtpSettings.UseResend,
            hasResendApiKey = !string.IsNullOrEmpty(_smtpSettings.ResendApiKey),
            resendApiKeyLength = _smtpSettings.ResendApiKey?.Length ?? 0,
            smtpHost = _smtpSettings.Host,
            smtpPort = _smtpSettings.Port,
            email = _smtpSettings.Email,
            displayName = _smtpSettings.DisplayName
        });
    }

    /// <summary>
    /// Send a test email to verify email service is working
    /// </summary>
    [HttpPost("test-email")]
    public async Task<IActionResult> TestEmail([FromQuery] string toEmail)
    {
        if (string.IsNullOrEmpty(toEmail))
            return BadRequest("Please provide 'toEmail' query parameter");

        try
        {
            await _emailService.SendOtpAsync(toEmail, "123456", "EmailVerification");
            return Ok(new { 
                success = true, 
                message = $"Test email sent to {toEmail}",
                method = _smtpSettings.UseResend ? "Resend API" : "SMTP"
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { 
                success = false, 
                error = ex.Message, 
                innerError = ex.InnerException?.Message,
                method = _smtpSettings.UseResend ? "Resend API" : "SMTP"
            });
        }
    }
}
