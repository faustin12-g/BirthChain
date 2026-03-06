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
    /// Check SMTP configuration (does not reveal password)
    /// </summary>
    [HttpGet("smtp-config")]
    public IActionResult GetSmtpConfig()
    {
        return Ok(new
        {
            host = _smtpSettings.Host,
            port = _smtpSettings.Port,
            email = _smtpSettings.Email,
            displayName = _smtpSettings.DisplayName,
            hasPassword = !string.IsNullOrEmpty(_smtpSettings.Password),
            passwordLength = _smtpSettings.Password?.Length ?? 0
        });
    }

    /// <summary>
    /// Send a test email to verify SMTP is working
    /// </summary>
    [HttpPost("test-email")]
    public async Task<IActionResult> TestEmail([FromQuery] string toEmail)
    {
        if (string.IsNullOrEmpty(toEmail))
            return BadRequest("Please provide 'toEmail' query parameter");

        try
        {
            await _emailService.SendOtpAsync(toEmail, "123456", "EmailVerification");
            return Ok(new { success = true, message = $"Test email sent to {toEmail}" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, error = ex.Message, innerError = ex.InnerException?.Message });
        }
    }
}
