using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class FacilitiesController : ControllerBase
{
    private readonly IFacilityService _facilityService;
    private readonly IActivityLogService _activityLog;

    public FacilitiesController(IFacilityService facilityService, IActivityLogService activityLog)
    {
        _facilityService = facilityService;
        _activityLog = activityLog;
    }

    /// <summary>Admin: Create a new healthcare facility.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateFacilityDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
            return BadRequest(new { message = "Facility name is required." });

        try
        {
            var facility = await _facilityService.CreateAsync(dto);

            var adminId = Guid.Parse(User.FindFirstValue("sub")!);
            await _activityLog.LogAsync(adminId, $"Created facility {dto.Name}");

            return CreatedAtAction(nameof(GetAll), null, facility);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>Admin: List all facilities.</summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAll()
    {
        var facilities = await _facilityService.GetAllAsync();
        return Ok(facilities);
    }

    /// <summary>Admin: Get a facility by ID.</summary>
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(Guid id)
    {
        var facility = await _facilityService.GetByIdAsync(id);
        if (facility is null)
            return NotFound(new { message = $"Facility '{id}' not found." });
        return Ok(facility);
    }

    /// <summary>Admin: Create a FacilityAdmin user assigned to a facility.</summary>
    [HttpPost("admins")]
    public async Task<IActionResult> CreateFacilityAdmin([FromBody] CreateFacilityAdminDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.FullName))
            return BadRequest(new { message = "Full name is required." });
        if (string.IsNullOrWhiteSpace(dto.Email))
            return BadRequest(new { message = "Email is required." });
        if (string.IsNullOrWhiteSpace(dto.Password) || dto.Password.Length < 6)
            return BadRequest(new { message = "Password must be at least 6 characters." });

        try
        {
            var result = await _facilityService.CreateFacilityAdminAsync(dto);

            var adminId = Guid.Parse(User.FindFirstValue("sub")!);
            await _activityLog.LogAsync(adminId, $"Created FacilityAdmin {dto.FullName}");

            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }
}
