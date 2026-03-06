using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BirthChain.Infrastructure.Services;

public sealed class FacilityService : IFacilityService
{
    private readonly IFacilityRepository _facilityRepo;
    private readonly IUserRepository _userRepo;
    private readonly IFcmNotificationService _fcmService;
    private readonly BirthChainDbContext _context;
    private readonly ILogger<FacilityService> _logger;

    public FacilityService(
        IFacilityRepository facilityRepo,
        IUserRepository userRepo,
        IFcmNotificationService fcmService,
        BirthChainDbContext context,
        ILogger<FacilityService> logger)
    {
        _facilityRepo = facilityRepo;
        _userRepo = userRepo;
        _fcmService = fcmService;
        _context = context;
        _logger = logger;
    }

    public async Task<FacilityDto> CreateAsync(CreateFacilityDto dto)
    {
        // Check uniqueness
        var existing = await _facilityRepo.GetByNameAsync(dto.Name);
        if (existing is not null)
            throw new InvalidOperationException($"A facility named '{dto.Name}' already exists.");

        var facility = new Facility
        {
            Name = dto.Name,
            Address = dto.Address,
            Phone = dto.Phone,
            Email = dto.Email,
            CreatedAt = DateTime.UtcNow
        };

        await _facilityRepo.AddAsync(facility);

        // Send notification to all admins
        await SendNotificationToAdminsAsync(
            "New Facility Registered",
            $"A new facility '{dto.Name}' has been registered."
        );

        return ToDto(facility);
    }

    private async Task SendNotificationToAdminsAsync(string title, string body)
    {
        try
        {
            // Get all admin users
            var allAdmins = await _context.Users
                .Where(u => u.Role == "Admin")
                .ToListAsync();

            _logger.LogInformation("Found {Count} admin users total", allAdmins.Count);

            // Save notification for ALL admins (for in-app display)
            foreach (var admin in allAdmins)
            {
                var notification = new Notification
                {
                    UserId = admin.Id,
                    Title = title,
                    Body = body,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);

                // Send push notification only if admin has FCM token
                if (!string.IsNullOrEmpty(admin.FcmToken))
                {
                    _logger.LogInformation("Sending push notification to admin {AdminId}", admin.Id);
                    await _fcmService.SendNotificationAsync(admin.FcmToken, title, body);
                }
            }

            if (allAdmins.Count > 0)
            {
                await _context.SaveChangesAsync();
                _logger.LogInformation("Saved {Count} notifications to database", allAdmins.Count);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending notifications to admins");
        }
    }

    public async Task<IReadOnlyList<FacilityDto>> GetAllAsync()
    {
        var facilities = await _facilityRepo.GetAllAsync();
        return facilities.Select(ToDto).ToList().AsReadOnly();
    }

    public async Task<FacilityDto?> GetByIdAsync(Guid id)
    {
        var facility = await _facilityRepo.GetByIdAsync(id);
        return facility is null ? null : ToDto(facility);
    }

    /// <summary>
    /// Admin creates a FacilityAdmin user assigned to a facility.
    /// </summary>
    public async Task<FacilityDto> CreateFacilityAdminAsync(CreateFacilityAdminDto dto)
    {
        // Validate facility exists
        var facility = await _facilityRepo.GetByIdAsync(dto.FacilityId)
            ?? throw new InvalidOperationException($"Facility '{dto.FacilityId}' not found.");

        // Check email uniqueness
        var existingUser = await _userRepo.GetByEmailAsync(dto.Email);
        if (existingUser is not null)
            throw new InvalidOperationException($"A user with email '{dto.Email}' already exists.");

        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            PasswordHash = AuthService.HashPassword(dto.Password),
            Role = "FacilityAdmin",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            FacilityId = dto.FacilityId
        };

        await _userRepo.AddAsync(user);
        return ToDto(facility);
    }

    private static FacilityDto ToDto(Facility f) => new()
    {
        Id = f.Id,
        Name = f.Name,
        Address = f.Address,
        Phone = f.Phone,
        Email = f.Email,
        CreatedAt = f.CreatedAt
    };
}
