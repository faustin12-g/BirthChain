using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _adminService;
    private readonly IActivityLogService _activityLog;

    public AdminController(IAdminService adminService, IActivityLogService activityLog)
    {
        _adminService = adminService;
        _activityLog = activityLog;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue("sub")!);

    // ══════════════════════════════════════════════════════════════════════════════
    // DASHBOARD
    // ══════════════════════════════════════════════════════════════════════════════

    /// <summary>GET api/admin/dashboard — Dashboard statistics</summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        var stats = await _adminService.GetDashboardStatsAsync();
        return Ok(stats);
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // FACILITY MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════

    /// <summary>GET api/admin/facilities — List all facilities with details</summary>
    [HttpGet("facilities")]
    public async Task<IActionResult> GetAllFacilities()
    {
        var facilities = await _adminService.GetAllFacilitiesAsync();
        return Ok(facilities);
    }

    /// <summary>GET api/admin/facilities/{id} — Get facility details</summary>
    [HttpGet("facilities/{id:guid}")]
    public async Task<IActionResult> GetFacility(Guid id)
    {
        var facility = await _adminService.GetFacilityByIdAsync(id);
        return facility is null 
            ? NotFound(new { message = "Facility not found." }) 
            : Ok(facility);
    }

    /// <summary>PUT api/admin/facilities/{id} — Update facility</summary>
    [HttpPut("facilities/{id:guid}")]
    public async Task<IActionResult> UpdateFacility(Guid id, [FromBody] UpdateFacilityDto dto)
    {
        try
        {
            var facility = await _adminService.UpdateFacilityAsync(id, dto);
            await _activityLog.LogAsync(CurrentUserId, $"Updated facility {facility.Name}");
            return Ok(facility);
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>POST api/admin/facilities/{id}/activate — Activate facility</summary>
    [HttpPost("facilities/{id:guid}/activate")]
    public async Task<IActionResult> ActivateFacility(Guid id)
    {
        try
        {
            await _adminService.ActivateFacilityAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Activated facility {id}");
            return Ok(new { message = "Facility activated successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>POST api/admin/facilities/{id}/deactivate — Deactivate facility</summary>
    [HttpPost("facilities/{id:guid}/deactivate")]
    public async Task<IActionResult> DeactivateFacility(Guid id)
    {
        try
        {
            await _adminService.DeactivateFacilityAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Deactivated facility {id}");
            return Ok(new { message = "Facility deactivated successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>DELETE api/admin/facilities/{id} — Delete facility</summary>
    [HttpDelete("facilities/{id:guid}")]
    public async Task<IActionResult> DeleteFacility(Guid id)
    {
        try
        {
            await _adminService.DeleteFacilityAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Deleted facility {id}");
            return Ok(new { message = "Facility deleted successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // USER MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════

    /// <summary>GET api/admin/users — List all users</summary>
    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        var users = await _adminService.GetAllUsersAsync();
        return Ok(users);
    }

    /// <summary>GET api/admin/users/role/{role} — List users by role</summary>
    [HttpGet("users/role/{role}")]
    public async Task<IActionResult> GetUsersByRole(string role)
    {
        var users = await _adminService.GetUsersByRoleAsync(role);
        return Ok(users);
    }

    /// <summary>GET api/admin/users/{id} — Get user details</summary>
    [HttpGet("users/{id:guid}")]
    public async Task<IActionResult> GetUser(Guid id)
    {
        var user = await _adminService.GetUserByIdAsync(id);
        return user is null 
            ? NotFound(new { message = "User not found." }) 
            : Ok(user);
    }

    /// <summary>PUT api/admin/users/{id} — Update user</summary>
    [HttpPut("users/{id:guid}")]
    public async Task<IActionResult> UpdateUser(Guid id, [FromBody] AdminUpdateUserDto dto)
    {
        try
        {
            var user = await _adminService.UpdateUserAsync(id, dto);
            await _activityLog.LogAsync(CurrentUserId, $"Updated user {user.Email}");
            return Ok(user);
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>POST api/admin/users/{id}/activate — Activate user</summary>
    [HttpPost("users/{id:guid}/activate")]
    public async Task<IActionResult> ActivateUser(Guid id)
    {
        try
        {
            await _adminService.ActivateUserAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Activated user {id}");
            return Ok(new { message = "User activated successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>POST api/admin/users/{id}/deactivate — Deactivate user</summary>
    [HttpPost("users/{id:guid}/deactivate")]
    public async Task<IActionResult> DeactivateUser(Guid id)
    {
        try
        {
            await _adminService.DeactivateUserAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Deactivated user {id}");
            return Ok(new { message = "User deactivated successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>DELETE api/admin/users/{id} — Delete user</summary>
    [HttpDelete("users/{id:guid}")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        try
        {
            await _adminService.DeleteUserAsync(id);
            await _activityLog.LogAsync(CurrentUserId, $"Deleted user {id}");
            return Ok(new { message = "User deleted successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // PROVIDER MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════

    /// <summary>GET api/admin/providers — List all providers</summary>
    [HttpGet("providers")]
    public async Task<IActionResult> GetAllProviders()
    {
        var providers = await _adminService.GetAllProvidersAsync();
        return Ok(providers);
    }

    /// <summary>GET api/admin/providers/facility/{facilityId} — List providers by facility</summary>
    [HttpGet("providers/facility/{facilityId:guid}")]
    public async Task<IActionResult> GetProvidersByFacility(Guid facilityId)
    {
        var providers = await _adminService.GetProvidersByFacilityAsync(facilityId);
        return Ok(providers);
    }

    /// <summary>GET api/admin/providers/{id} — Get provider details</summary>
    [HttpGet("providers/{id:guid}")]
    public async Task<IActionResult> GetProvider(Guid id)
    {
        var provider = await _adminService.GetProviderByIdAsync(id);
        return provider is null 
            ? NotFound(new { message = "Provider not found." }) 
            : Ok(provider);
    }

    /// <summary>PUT api/admin/providers/{id} — Update provider</summary>
    [HttpPut("providers/{id:guid}")]
    public async Task<IActionResult> UpdateProvider(Guid id, [FromBody] UpdateProviderDto dto)
    {
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

    /// <summary>POST api/admin/providers/{id}/activate — Activate provider</summary>
    [HttpPost("providers/{id:guid}/activate")]
    public async Task<IActionResult> ActivateProvider(Guid id)
    {
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

    /// <summary>POST api/admin/providers/{id}/deactivate — Deactivate provider</summary>
    [HttpPost("providers/{id:guid}/deactivate")]
    public async Task<IActionResult> DeactivateProvider(Guid id)
    {
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

    /// <summary>DELETE api/admin/providers/{id} — Delete provider</summary>
    [HttpDelete("providers/{id:guid}")]
    public async Task<IActionResult> DeleteProvider(Guid id)
    {
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
