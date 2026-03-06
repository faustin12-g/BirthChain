using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

/// <summary>
/// Facility Admin endpoints for managing providers within their facility.
/// </summary>
[ApiController]
[Route("api/facility-admin")]
[Authorize(Roles = "FacilityAdmin")]
public class FacilityAdminController : ControllerBase
{
    private readonly IAdminService _adminService;
    private readonly IUserRepository _userRepo;
    private readonly IActivityLogService _activityLog;

    public FacilityAdminController(
        IAdminService adminService,
        IUserRepository userRepo,
        IActivityLogService activityLog)
    {
        _adminService = adminService;
        _userRepo = userRepo;
        _activityLog = activityLog;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue("sub")!);

    private async Task<Guid?> GetCurrentUserFacilityIdAsync()
    {
        var user = await _userRepo.GetByIdAsync(CurrentUserId);
        return user?.FacilityId;
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // FACILITY INFO
    // ══════════════════════════════════════════════════════════════════════════════

    /// <summary>GET api/facility-admin/my-facility — Get current facility info</summary>
    [HttpGet("my-facility")]
    public async Task<IActionResult> GetMyFacility()
    {
        var facilityId = await GetCurrentUserFacilityIdAsync();
        if (!facilityId.HasValue)
            return BadRequest(new { message = "You are not assigned to a facility." });

        var facility = await _adminService.GetFacilityByIdAsync(facilityId.Value);
        return facility is null 
            ? NotFound(new { message = "Facility not found." }) 
            : Ok(facility);
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // PROVIDER MANAGEMENT (within facility)
    // ══════════════════════════════════════════════════════════════════════════════

    /// <summary>GET api/facility-admin/providers — List providers in my facility</summary>
    [HttpGet("providers")]
    public async Task<IActionResult> GetProviders()
    {
        var facilityId = await GetCurrentUserFacilityIdAsync();
        if (!facilityId.HasValue)
            return BadRequest(new { message = "You are not assigned to a facility." });

        var providers = await _adminService.GetProvidersByFacilityAsync(facilityId.Value);
        return Ok(providers);
    }

    /// <summary>GET api/facility-admin/providers/{id} — Get provider details</summary>
    [HttpGet("providers/{id:guid}")]
    public async Task<IActionResult> GetProvider(Guid id)
    {
        var facilityId = await GetCurrentUserFacilityIdAsync();
        if (!facilityId.HasValue)
            return BadRequest(new { message = "You are not assigned to a facility." });

        var provider = await _adminService.GetProviderByIdAsync(id);
        if (provider is null)
            return NotFound(new { message = "Provider not found." });

        // Ensure provider belongs to this facility
        if (provider.FacilityId != facilityId.Value)
            return Forbid();

        return Ok(provider);
    }

    /// <summary>PUT api/facility-admin/providers/{id} — Update provider</summary>
    [HttpPut("providers/{id:guid}")]
    public async Task<IActionResult> UpdateProvider(Guid id, [FromBody] UpdateProviderDto dto)
    {
        var facilityId = await GetCurrentUserFacilityIdAsync();
        if (!facilityId.HasValue)
            return BadRequest(new { message = "You are not assigned to a facility." });

        var existing = await _adminService.GetProviderByIdAsync(id);
        if (existing is null)
            return NotFound(new { message = "Provider not found." });

        if (existing.FacilityId != facilityId.Value)
            return Forbid();

        try
        {
            var provider = await _adminService.UpdateProviderAsync(id, dto);
            await _activityLog.LogAsync(CurrentUserId, $"Updated provider {provider.Email}");
            return Ok(provider);
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>POST api/facility-admin/providers/{id}/activate — Activate provider</summary>
    [HttpPost("providers/{id:guid}/activate")]
    public async Task<IActionResult> ActivateProvider(Guid id)
    {
        var facilityId = await GetCurrentUserFacilityIdAsync();
        if (!facilityId.HasValue)
            return BadRequest(new { message = "You are not assigned to a facility." });

        var existing = await _adminService.GetProviderByIdAsync(id);
        if (existing is null)
            return NotFound(new { message = "Provider not found." });

        if (existing.FacilityId != facilityId.Value)
            return Forbid();

        try
        {
            await _adminService.ActivateProviderAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Activated provider {id}");
            return Ok(new { message = "Provider activated successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>POST api/facility-admin/providers/{id}/deactivate — Deactivate provider</summary>
    [HttpPost("providers/{id:guid}/deactivate")]
    public async Task<IActionResult> DeactivateProvider(Guid id)
    {
        var facilityId = await GetCurrentUserFacilityIdAsync();
        if (!facilityId.HasValue)
            return BadRequest(new { message = "You are not assigned to a facility." });

        var existing = await _adminService.GetProviderByIdAsync(id);
        if (existing is null)
            return NotFound(new { message = "Provider not found." });

        if (existing.FacilityId != facilityId.Value)
            return Forbid();

        try
        {
            await _adminService.DeactivateProviderAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Deactivated provider {id}");
            return Ok(new { message = "Provider deactivated successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>DELETE api/facility-admin/providers/{id} — Delete provider</summary>
    [HttpDelete("providers/{id:guid}")]
    public async Task<IActionResult> DeleteProvider(Guid id)
    {
        var facilityId = await GetCurrentUserFacilityIdAsync();
        if (!facilityId.HasValue)
            return BadRequest(new { message = "You are not assigned to a facility." });

        var existing = await _adminService.GetProviderByIdAsync(id);
        if (existing is null)
            return NotFound(new { message = "Provider not found." });

        if (existing.FacilityId != facilityId.Value)
            return Forbid();

        try
        {
            await _adminService.DeleteProviderAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Deleted provider {id}");
            return Ok(new { message = "Provider deleted successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
