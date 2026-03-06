using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Services;

namespace BirthChain.Infrastructure.Services;

public sealed class UserService : IUserService
{
    private readonly IUserRepository _userRepo;
    private readonly IFacilityRepository _facilityRepo;
    private readonly IProviderRepository _providerRepo;
    private readonly IClientRepository _clientRepo;
    private readonly IRecordRepository _recordRepo;
    private readonly IActivityLogRepository _activityLogRepo;

    public UserService(
        IUserRepository userRepo,
        IFacilityRepository facilityRepo,
        IProviderRepository providerRepo,
        IClientRepository clientRepo,
        IRecordRepository recordRepo,
        IActivityLogRepository activityLogRepo)
    {
        _userRepo = userRepo;
        _facilityRepo = facilityRepo;
        _providerRepo = providerRepo;
        _clientRepo = clientRepo;
        _recordRepo = recordRepo;
        _activityLogRepo = activityLogRepo;
    }

    public async Task<UserDto> CreateAsync(CreateUserDto dto)
    {
        var existing = await _userRepo.GetByEmailAsync(dto.Email);
        if (existing is not null)
            throw new InvalidOperationException($"A user with email '{dto.Email}' already exists.");

        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            PasswordHash = AuthService.HashPassword(dto.Password),
            Role = dto.Role,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _userRepo.AddAsync(user);
        return ToDto(created);
    }

    public async Task<IReadOnlyList<UserDto>> GetAllAsync()
    {
        var users = await _userRepo.GetAllAsync();
        return users.Select(ToDto).ToList().AsReadOnly();
    }

    public async Task<UserDto?> GetByIdAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id);
        return user is null ? null : ToDto(user);
    }

    public async Task<bool> ToggleActiveAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id);
        if (user is null) return false;

        user.IsActive = !user.IsActive;
        await _userRepo.UpdateAsync(user);
        return true;
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id);
        if (user is null) return false;

        // Soft-delete: deactivate the user
        user.IsActive = false;
        await _userRepo.UpdateAsync(user);
        return true;
    }

    public async Task<AdminStatsDto> GetStatsAsync()
    {
        var users = await _userRepo.GetAllAsync();
        var facilities = await _facilityRepo.GetAllAsync();
        var providers = await _providerRepo.GetAllAsync();
        var clients = await _clientRepo.GetAllAsync();
        var logs = await _activityLogRepo.GetAllAsync();

        // Count records across all clients
        var totalRecords = 0;
        foreach (var client in clients)
        {
            var records = await _recordRepo.GetByClientIdAsync(client.Id);
            totalRecords += records.Count;
        }

        var roleGroups = users.GroupBy(u => u.Role)
            .ToDictionary(g => g.Key, g => g.Count());

        return new AdminStatsDto
        {
            TotalUsers = users.Count,
            ActiveUsers = users.Count(u => u.IsActive),
            TotalFacilities = facilities.Count,
            TotalProviders = providers.Count,
            TotalClients = clients.Count,
            TotalRecords = totalRecords,
            TotalActivityLogs = logs.Count,
            UsersByRole = roleGroups
        };
    }

    private static UserDto ToDto(User u) => new()
    {
        Id = u.Id,
        FullName = u.FullName,
        Email = u.Email,
        Role = u.Role,
        IsActive = u.IsActive,
        CreatedAt = u.CreatedAt
    };
}
