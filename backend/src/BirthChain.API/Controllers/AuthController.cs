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
}
