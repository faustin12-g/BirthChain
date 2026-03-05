using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class ActivityLogsController : ControllerBase
{
    private readonly IActivityLogService _logService;

    public ActivityLogsController(IActivityLogService logService) => _logService = logService;

    /// <summary>Admin: View all activity logs.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var logs = await _logService.GetAllAsync();
        return Ok(logs);
    }

    /// <summary>Admin: View activity logs for a specific user.</summary>
    [HttpGet("by-user/{userId:guid}")]
    public async Task<IActionResult> GetByUser(Guid userId)
    {
        var logs = await _logService.GetByUserIdAsync(userId);
        return Ok(logs);
    }
}
