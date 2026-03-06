using System.Security.Claims;
using BirthChain.Infrastructure.Data;
using BirthChain.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationController : ControllerBase
{
    private readonly BirthChainDbContext _context;
    private readonly IFcmNotificationService _fcmService;
    private readonly ILogger<NotificationController> _logger;

    public NotificationController(
        BirthChainDbContext context, 
        IFcmNotificationService fcmService,
        ILogger<NotificationController> logger)
    {
        _context = context;
        _fcmService = fcmService;
        _logger = logger;
    }

    private Guid? GetUserId()
    {
        // JWT tokens use "sub" claim for user ID
        var userIdClaim = User.FindFirst("sub")?.Value 
            ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        if (Guid.TryParse(userIdClaim, out var userId))
            return userId;
        return null;
    }

    /// <summary>
    /// Save device FCM token for push notifications
    /// </summary>
    [HttpPost("token")]
    public async Task<IActionResult> SaveDeviceToken([FromBody] DeviceTokenDto dto)
    {
        var userId = GetUserId();
        if (userId == null)
        {
            _logger.LogWarning("Failed to get user ID from claims. Claims: {Claims}", 
                string.Join(", ", User.Claims.Select(c => $"{c.Type}={c.Value}")));
            return Unauthorized();
        }

        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null)
        {
            _logger.LogWarning("User {UserId} not found in database", userId);
            return NotFound("User not found");
        }

        user.FcmToken = dto.Token;
        await _context.SaveChangesAsync();

        _logger.LogInformation("FCM token saved for user {UserId}, token starts with: {TokenStart}", 
            userId, dto.Token?.Substring(0, Math.Min(20, dto.Token?.Length ?? 0)));

        return Ok(new { message = "Device token saved successfully" });
    }

    /// <summary>
    /// Get user's notifications
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetNotifications()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var notifications = await _context.Notifications
            .Where(n => n.UserId == userId.Value)
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new
            {
                n.Id,
                n.Title,
                n.Body,
                n.IsRead,
                n.CreatedAt
            })
            .ToListAsync();

        return Ok(notifications);
    }

    /// <summary>
    /// Mark notification as read
    /// </summary>
    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId.Value);

        if (notification == null)
            return NotFound();

        notification.IsRead = true;
        await _context.SaveChangesAsync();

        return Ok();
    }

    /// <summary>
    /// Mark all notifications as read
    /// </summary>
    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        await _context.Notifications
            .Where(n => n.UserId == userId.Value && !n.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));

        return Ok();
    }

    /// <summary>
    /// Debug endpoint to check notification setup status
    /// </summary>
    [HttpGet("debug")]
    public async Task<IActionResult> GetDebugInfo()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var user = await _context.Users.FindAsync(userId.Value);
        var adminsWithTokens = await _context.Users
            .Where(u => u.Role == "Admin" && !string.IsNullOrEmpty(u.FcmToken))
            .CountAsync();
        var totalAdmins = await _context.Users
            .Where(u => u.Role == "Admin")
            .CountAsync();

        return Ok(new
        {
            CurrentUserId = userId,
            CurrentUserRole = user?.Role,
            CurrentUserHasFcmToken = !string.IsNullOrEmpty(user?.FcmToken),
            TotalAdmins = totalAdmins,
            AdminsWithFcmTokens = adminsWithTokens
        });
    }
}

public record DeviceTokenDto(string Token);
