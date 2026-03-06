using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin,FacilityAdmin")]
public class ProvidersController : ControllerBase
{
    private readonly IProviderService _providerService;
    private readonly IActivityLogService _activityLog;
    private readonly IUserRepository _userRepo;

    public ProvidersController(
        IProviderService providerService,
        IActivityLogService activityLog,
        IUserRepository userRepo)
    {
        _providerService = providerService;
        _activityLog = activityLog;
        _userRepo = userRepo;
    }

    /// <summary>Admin or FacilityAdmin: Create a Provider (User + profile).
    /// FacilityAdmin can only create providers for their own facility.</summary>
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
        if (dto.FacilityId == Guid.Empty)
            return BadRequest(new { message = "FacilityId is required." });

        // If FacilityAdmin, enforce they only create providers for their own facility
        var callerUserId = Guid.Parse(User.FindFirstValue("sub")!);
        var callerRole = User.FindFirstValue("role");
        if (callerRole == "FacilityAdmin")
        {
            var callerUser = await _userRepo.GetByIdAsync(callerUserId);
            if (callerUser?.FacilityId != dto.FacilityId)
                return Forbid();
        }

        try
        {
            var provider = await _providerService.CreateAsync(dto);
            await _activityLog.LogAsync(callerUserId, $"Created provider {dto.FullName}");
            return CreatedAtAction(nameof(GetAll), null, provider);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>Admin: List all providers. FacilityAdmin: List providers for own facility.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var callerUserId = Guid.Parse(User.FindFirstValue("sub")!);
        var callerRole = User.FindFirstValue("role");

        if (callerRole == "FacilityAdmin")
        {
            var callerUser = await _userRepo.GetByIdAsync(callerUserId);
            if (callerUser?.FacilityId is not null)
            {
                var facilityProviders = await _providerService.GetByFacilityIdAsync(callerUser.FacilityId.Value);
                return Ok(facilityProviders);
            }
            return Ok(Array.Empty<ProviderDto>());
        }

        var providers = await _providerService.GetAllAsync();
        return Ok(providers);
    }

    /// <summary>Provider: View own profile.</summary>
    [HttpGet("me")]
    [Authorize(Roles = "Provider")]
    public async Task<IActionResult> GetMyProfile()
    {
        var userId = Guid.Parse(User.FindFirstValue("sub")!);
        var profile = await _providerService.GetByUserIdAsync(userId);
        if (profile is null)
            return NotFound(new { message = "Provider profile not found." });
        return Ok(profile);
    }

    /// <summary>Get providers by facility ID.</summary>
    [HttpGet("by-facility/{facilityId:guid}")]
    public async Task<IActionResult> GetByFacility(Guid facilityId)
    {
        var providers = await _providerService.GetByFacilityIdAsync(facilityId);
        return Ok(providers);
    }
}
