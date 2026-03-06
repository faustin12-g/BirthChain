using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Services;

public sealed class FacilityService : IFacilityService
{
    private readonly IFacilityRepository _facilityRepo;
    private readonly IUserRepository _userRepo;
    private readonly IFcmNotificationService _fcmService;
    private readonly BirthChainDbContext _context;

    public FacilityService(
        IFacilityRepository facilityRepo, 
        IUserRepository userRepo,
        IFcmNotificationService fcmService,
        BirthChainDbContext context)
    {
        _facilityRepo = facilityRepo;
        _userRepo = userRepo;
        _fcmService = fcmService;
        _context = context;
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
        var admins = await _context.Users
            .Where(u => u.Role == "Admin" && !string.IsNullOrEmpty(u.FcmToken))
            .ToListAsync();

        foreach (var admin in admins)
        {
            // Save notification for in-app display
            var notification = new Notification
            {
                UserId = admin.Id,
                Title = title,
                Body = body,
                CreatedAt = DateTime.UtcNow
            };
            _context.Notifications.Add(notification);

            // Send push notification
            if (!string.IsNullOrEmpty(admin.FcmToken))
            {
                await _fcmService.SendNotificationAsync(admin.FcmToken, title, body);
            }
        }

        await _context.SaveChangesAsync();
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
