using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly IUserService _userService;

    public AdminController(IUserService userService) => _userService = userService;

    /// <summary>GET api/admin/stats — Dashboard statistics</summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var stats = await _userService.GetStatsAsync();
        return Ok(stats);
    }

    /// <summary>GET api/admin/users — List all users</summary>
    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        var users = await _userService.GetAllAsync();
        return Ok(users);
    }

    /// <summary>GET api/admin/users/{id} — Get a single user</summary>
    [HttpGet("users/{id:guid}")]
    public async Task<IActionResult> GetUser(Guid id)
    {
        var user = await _userService.GetByIdAsync(id);
        return user is null ? NotFound(new { message = "User not found." }) : Ok(user);
    }

    /// <summary>PUT api/admin/users/{id}/toggle-active — Enable/disable a user</summary>
    [HttpPut("users/{id:guid}/toggle-active")]
    public async Task<IActionResult> ToggleActive(Guid id)
    {
        var ok = await _userService.ToggleActiveAsync(id);
        return ok
            ? Ok(new { message = "User status updated." })
            : NotFound(new { message = "User not found." });
    }

    /// <summary>DELETE api/admin/users/{id} — Soft-delete a user</summary>
    [HttpDelete("users/{id:guid}")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        var ok = await _userService.DeleteAsync(id);
        return ok
            ? Ok(new { message = "User deactivated." })
            : NotFound(new { message = "User not found." });
    }
}
