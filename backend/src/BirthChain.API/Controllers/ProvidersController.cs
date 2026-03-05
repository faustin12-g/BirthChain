using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class ProvidersController : ControllerBase
{
    private readonly IProviderService _providerService;
    private readonly IActivityLogService _activityLog;

    public ProvidersController(IProviderService providerService, IActivityLogService activityLog)
    {
        _providerService = providerService;
        _activityLog = activityLog;
    }

    /// <summary>Admin: Create a Provider (User + profile).</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateProviderDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.FullName))
            return BadRequest(new { message = "FullName is required." });
        if (string.IsNullOrWhiteSpace(dto.Email))
            return BadRequest(new { message = "Email is required." });
        if (string.IsNullOrWhiteSpace(dto.Password) || dto.Password.Length < 6)
            return BadRequest(new { message = "Password must be at least 6 characters." });
        if (string.IsNullOrWhiteSpace(dto.LicenseNumber))
            return BadRequest(new { message = "LicenseNumber is required." });

        try
        {
            var provider = await _providerService.CreateAsync(dto);

            var adminId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            await _activityLog.LogAsync(adminId, $"Created provider {dto.FullName}");

            return CreatedAtAction(nameof(GetAll), null, provider);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>Admin: List all providers.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var providers = await _providerService.GetAllAsync();
        return Ok(providers);
    }

    /// <summary>Provider: View own profile.</summary>
    [HttpGet("me")]
    [Authorize(Roles = "Provider")]
    public async Task<IActionResult> GetMyProfile()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var profile = await _providerService.GetByUserIdAsync(userId);
        if (profile is null)
            return NotFound(new { message = "Provider profile not found." });
        return Ok(profile);
    }
}
