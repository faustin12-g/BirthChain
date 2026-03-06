using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IActivityLogService _activityLog;

    public AuthController(IAuthService authService, IActivityLogService activityLog)
    {
        _authService = authService;
        _activityLog = activityLog;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            return BadRequest(new { message = "Email and password are required." });

        var result = await _authService.LoginAsync(request);
        if (result is null)
            return Unauthorized(new { message = "Invalid email or password." });

        await _activityLog.LogAsync(result.UserId, $"Logged in ({result.Role})");

        return Ok(result);
    }

    /// <summary>Patient self-registration. Creates user + client and returns JWT.</summary>
    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterPatientDto request)
    {
        if (string.IsNullOrWhiteSpace(request.FullName))
            return BadRequest(new { message = "Full name is required." });
        if (string.IsNullOrWhiteSpace(request.Email))
            return BadRequest(new { message = "Email is required." });
        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            return BadRequest(new { message = "Password must be at least 6 characters." });

        try
        {
            var result = await _authService.RegisterPatientAsync(request);
            await _activityLog.LogAsync(result.UserId, "Patient self-registered");
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>Send a 6-digit OTP for email verification.</summary>
    [HttpPost("send-otp")]
    [AllowAnonymous]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            return BadRequest(new { message = "Email is required." });

        try
        {
            await _authService.SendVerificationOtpAsync(request.Email);
            return Ok(new { message = "Verification code sent to your email." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Verify email using OTP code.</summary>
    [HttpPost("verify-email")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyEmail([FromBody] VerifyOtpRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code))
            return BadRequest(new { message = "Email and code are required." });

        var success = await _authService.VerifyEmailAsync(request.Email, request.Code);
        if (!success)
            return BadRequest(new { message = "Invalid or expired code." });

        return Ok(new { message = "Email verified successfully." });
    }

    /// <summary>Send a 6-digit OTP for password reset.</summary>
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            return BadRequest(new { message = "Email is required." });

        try
        {
            await _authService.SendPasswordResetOtpAsync(request.Email);
            return Ok(new { message = "Password reset code sent to your email." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Reset password using OTP code.</summary>
    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Code) || string.IsNullOrWhiteSpace(request.NewPassword))
            return BadRequest(new { message = "Email, code, and new password are required." });

        if (request.NewPassword.Length < 6)
            return BadRequest(new { message = "Password must be at least 6 characters." });

        var success = await _authService.ResetPasswordAsync(request.Email, request.Code, request.NewPassword);
        if (!success)
            return BadRequest(new { message = "Invalid or expired code." });

        return Ok(new { message = "Password reset successfully." });
    }
}
