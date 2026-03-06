using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;

namespace BirthChain.Infrastructure.Services;

public sealed class AdminService : IAdminService
{
    private readonly IFacilityRepository _facilityRepo;
    private readonly IUserRepository _userRepo;
    private readonly IProviderRepository _providerRepo;
    private readonly IRecordRepository _recordRepo;
    private readonly IClientRepository _clientRepo;

    public AdminService(
        IFacilityRepository facilityRepo,
        IUserRepository userRepo,
        IProviderRepository providerRepo,
        IRecordRepository recordRepo,
        IClientRepository clientRepo)
    {
        _facilityRepo = facilityRepo;
        _userRepo = userRepo;
        _providerRepo = providerRepo;
        _recordRepo = recordRepo;
        _clientRepo = clientRepo;
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // DASHBOARD & STATISTICS
    // ══════════════════════════════════════════════════════════════════════════════

    public async Task<DashboardStatsDto> GetDashboardStatsAsync()
    {
        var totalFacilities = await _facilityRepo.CountAsync();
        var activeFacilities = await _facilityRepo.CountActiveAsync();
        var users = await _userRepo.GetAllAsync();
        var totalProviders = await _providerRepo.CountAsync();
        var clients = await _clientRepo.GetAllAsync();
        var records = await _recordRepo.GetAllAsync();

        return new DashboardStatsDto
        {
            TotalFacilities = totalFacilities,
            ActiveFacilities = activeFacilities,
            TotalUsers = users.Count,
            ActiveUsers = users.Count(u => u.IsActive),
            TotalProviders = totalProviders,
            TotalPatients = clients.Count,
            TotalRecords = records.Count
        };
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // FACILITY MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════

    public async Task<IReadOnlyList<FacilityDetailDto>> GetAllFacilitiesAsync()
    {
        var facilities = await _facilityRepo.GetAllAsync();
        var result = new List<FacilityDetailDto>();

        foreach (var f in facilities)
        {
            var providers = await _providerRepo.GetByFacilityIdAsync(f.Id);
            var users = await _userRepo.GetByFacilityIdAsync(f.Id);

            result.Add(new FacilityDetailDto
            {
                Id = f.Id,
                Name = f.Name,
                Address = f.Address,
                Phone = f.Phone,
                Email = f.Email,
                IsActive = f.IsActive,
                CreatedAt = f.CreatedAt,
                ProviderCount = providers.Count,
                UserCount = users.Count
            });
        }

        return result;
    }

    public async Task<FacilityDetailDto?> GetFacilityByIdAsync(Guid id)
    {
        var f = await _facilityRepo.GetByIdAsync(id);
        if (f is null) return null;

        var providers = await _providerRepo.GetByFacilityIdAsync(f.Id);
        var users = await _userRepo.GetByFacilityIdAsync(f.Id);

        return new FacilityDetailDto
        {
            Id = f.Id,
            Name = f.Name,
            Address = f.Address,
            Phone = f.Phone,
            Email = f.Email,
            IsActive = f.IsActive,
            CreatedAt = f.CreatedAt,
            ProviderCount = providers.Count,
            UserCount = users.Count
        };
    }

    public async Task<FacilityDetailDto> UpdateFacilityAsync(Guid id, UpdateFacilityDto dto)
    {
        var facility = await _facilityRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Facility not found.");

        if (!string.IsNullOrWhiteSpace(dto.Name)) facility.Name = dto.Name;
        if (!string.IsNullOrWhiteSpace(dto.Address)) facility.Address = dto.Address;
        if (!string.IsNullOrWhiteSpace(dto.Phone)) facility.Phone = dto.Phone;
        if (!string.IsNullOrWhiteSpace(dto.Email)) facility.Email = dto.Email;

        await _facilityRepo.UpdateAsync(facility);

        return (await GetFacilityByIdAsync(id))!;
    }

    public async Task ActivateFacilityAsync(Guid id)
    {
        var facility = await _facilityRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Facility not found.");

        facility.IsActive = true;
        await _facilityRepo.UpdateAsync(facility);

        // Also activate all users in the facility
        var users = await _userRepo.GetByFacilityIdAsync(id);
        foreach (var user in users)
        {
            user.IsActive = true;
            await _userRepo.UpdateAsync(user);
        }
    }

    public async Task DeactivateFacilityAsync(Guid id)
    {
        var facility = await _facilityRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Facility not found.");

        facility.IsActive = false;
        await _facilityRepo.UpdateAsync(facility);

        // Also deactivate all users in the facility
        var users = await _userRepo.GetByFacilityIdAsync(id);
        foreach (var user in users)
        {
            user.IsActive = false;
            await _userRepo.UpdateAsync(user);
        }
    }

    public async Task DeleteFacilityAsync(Guid id)
    {
        var facility = await _facilityRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Facility not found.");

        // Check if facility has any providers
        var providers = await _providerRepo.GetByFacilityIdAsync(id);
        if (providers.Count > 0)
        {
            throw new InvalidOperationException(
                $"Cannot delete facility with {providers.Count} provider(s). Please reassign or delete providers first.");
        }

        // Check if facility has any users
        var users = await _userRepo.GetByFacilityIdAsync(id);
        if (users.Count > 0)
        {
            throw new InvalidOperationException(
                $"Cannot delete facility with {users.Count} user(s). Please reassign or delete users first.");
        }

        await _facilityRepo.DeleteAsync(id);
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // USER MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════

    public async Task<IReadOnlyList<UserDetailDto>> GetAllUsersAsync()
    {
        var users = await _userRepo.GetAllAsync();
        return await MapUsersToDetailDtos(users);
    }

    public async Task<IReadOnlyList<UserDetailDto>> GetUsersByRoleAsync(string role)
    {
        var users = await _userRepo.GetByRoleAsync(role);
        return await MapUsersToDetailDtos(users);
    }

    public async Task<UserDetailDto?> GetUserByIdAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id);
        if (user is null) return null;

        string? facilityName = null;
        if (user.FacilityId.HasValue)
        {
            var facility = await _facilityRepo.GetByIdAsync(user.FacilityId.Value);
            facilityName = facility?.Name;
        }

        return new UserDetailDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role,
            Phone = user.Phone,
            ProfileImageUrl = user.ProfileImageUrl,
            IsActive = user.IsActive,
            IsEmailVerified = user.IsEmailVerified,
            CreatedAt = user.CreatedAt,
            FacilityId = user.FacilityId,
            FacilityName = facilityName
        };
    }

    public async Task<UserDetailDto> UpdateUserAsync(Guid id, AdminUpdateUserDto dto)
    {
        var user = await _userRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("User not found.");

        if (!string.IsNullOrWhiteSpace(dto.FullName)) user.FullName = dto.FullName;
        if (!string.IsNullOrWhiteSpace(dto.Phone)) user.Phone = dto.Phone;
        if (!string.IsNullOrWhiteSpace(dto.Role)) user.Role = dto.Role;
        if (dto.FacilityId.HasValue) user.FacilityId = dto.FacilityId;

        await _userRepo.UpdateAsync(user);

        return (await GetUserByIdAsync(id))!;
    }

    public async Task ActivateUserAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("User not found.");

        user.IsActive = true;
        await _userRepo.UpdateAsync(user);
    }

    public async Task DeactivateUserAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("User not found.");

        // Prevent deactivating self or the last admin
        if (user.Role == "Admin")
        {
            var admins = await _userRepo.GetByRoleAsync("Admin");
            var activeAdmins = admins.Count(a => a.IsActive);
            if (activeAdmins <= 1)
            {
                throw new InvalidOperationException("Cannot deactivate the last active admin.");
            }
        }

        user.IsActive = false;
        await _userRepo.UpdateAsync(user);
    }

    public async Task DeleteUserAsync(Guid id)
    {
        var user = await _userRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("User not found.");

        // Prevent deleting the last admin
        if (user.Role == "Admin")
        {
            var admins = await _userRepo.GetByRoleAsync("Admin");
            if (admins.Count <= 1)
            {
                throw new InvalidOperationException("Cannot delete the last admin.");
            }
        }

        // If user has a provider profile, delete it first
        var provider = await _providerRepo.GetByUserIdAsync(id);
        if (provider is not null)
        {
            await _providerRepo.DeleteAsync(provider.Id);
        }

        await _userRepo.DeleteAsync(id);
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // PROVIDER MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════

    public async Task<IReadOnlyList<ProviderDetailDto>> GetAllProvidersAsync()
    {
        var providers = await _providerRepo.GetAllAsync();
        return await MapProvidersToDetailDtos(providers);
    }

    public async Task<IReadOnlyList<ProviderDetailDto>> GetProvidersByFacilityAsync(Guid facilityId)
    {
        var providers = await _providerRepo.GetByFacilityIdAsync(facilityId);
        return await MapProvidersToDetailDtos(providers);
    }

    public async Task<ProviderDetailDto?> GetProviderByIdAsync(Guid id)
    {
        var provider = await _providerRepo.GetByIdAsync(id);
        if (provider is null) return null;

        var user = await _userRepo.GetByIdAsync(provider.UserId);
        var facility = await _facilityRepo.GetByIdAsync(provider.FacilityId);

        return new ProviderDetailDto
        {
            Id = provider.Id,
            UserId = provider.UserId,
            FullName = user?.FullName ?? "",
            Email = user?.Email ?? "",
            Phone = user?.Phone,
            ProfileImageUrl = user?.ProfileImageUrl,
            LicenseNumber = provider.LicenseNumber,
            Specialty = provider.Specialty,
            FacilityId = provider.FacilityId,
            FacilityName = facility?.Name ?? "",
            IsActive = user?.IsActive ?? false,
            CreatedAt = user?.CreatedAt ?? DateTime.UtcNow
        };
    }

    public async Task<ProviderDetailDto> UpdateProviderAsync(Guid id, UpdateProviderDto dto)
    {
        var provider = await _providerRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Provider not found.");

        var user = await _userRepo.GetByIdAsync(provider.UserId)
            ?? throw new InvalidOperationException("Provider user not found.");

        if (!string.IsNullOrWhiteSpace(dto.FullName)) user.FullName = dto.FullName;
        if (!string.IsNullOrWhiteSpace(dto.Phone)) user.Phone = dto.Phone;
        if (!string.IsNullOrWhiteSpace(dto.LicenseNumber)) provider.LicenseNumber = dto.LicenseNumber;
        if (!string.IsNullOrWhiteSpace(dto.Specialty)) provider.Specialty = dto.Specialty;

        await _userRepo.UpdateAsync(user);
        await _providerRepo.UpdateAsync(provider);

        return (await GetProviderByIdAsync(id))!;
    }

    public async Task ActivateProviderAsync(Guid id)
    {
        var provider = await _providerRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Provider not found.");

        var user = await _userRepo.GetByIdAsync(provider.UserId)
            ?? throw new InvalidOperationException("Provider user not found.");

        user.IsActive = true;
        await _userRepo.UpdateAsync(user);
    }

    public async Task DeactivateProviderAsync(Guid id)
    {
        var provider = await _providerRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Provider not found.");

        var user = await _userRepo.GetByIdAsync(provider.UserId)
            ?? throw new InvalidOperationException("Provider user not found.");

        user.IsActive = false;
        await _userRepo.UpdateAsync(user);
    }

    public async Task DeleteProviderAsync(Guid id)
    {
        var provider = await _providerRepo.GetByIdAsync(id)
            ?? throw new InvalidOperationException("Provider not found.");

        // Delete the provider profile
        await _providerRepo.DeleteAsync(id);

        // Also delete the associated user
        await _userRepo.DeleteAsync(provider.UserId);
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // PRIVATE HELPERS
    // ══════════════════════════════════════════════════════════════════════════════

    private async Task<IReadOnlyList<UserDetailDto>> MapUsersToDetailDtos(IReadOnlyList<BirthChain.Core.Entities.User> users)
    {
        var result = new List<UserDetailDto>();

        foreach (var user in users)
        {
            string? facilityName = null;
            if (user.FacilityId.HasValue)
            {
                var facility = await _facilityRepo.GetByIdAsync(user.FacilityId.Value);
                facilityName = facility?.Name;
            }

            result.Add(new UserDetailDto
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role,
                Phone = user.Phone,
                ProfileImageUrl = user.ProfileImageUrl,
                IsActive = user.IsActive,
                IsEmailVerified = user.IsEmailVerified,
                CreatedAt = user.CreatedAt,
                FacilityId = user.FacilityId,
                FacilityName = facilityName
            });
        }

        return result;
    }

    private async Task<IReadOnlyList<ProviderDetailDto>> MapProvidersToDetailDtos(IReadOnlyList<BirthChain.Core.Entities.Provider> providers)
    {
        var result = new List<ProviderDetailDto>();

        foreach (var provider in providers)
        {
            var user = await _userRepo.GetByIdAsync(provider.UserId);
            var facility = await _facilityRepo.GetByIdAsync(provider.FacilityId);

            result.Add(new ProviderDetailDto
            {
                Id = provider.Id,
                UserId = provider.UserId,
                FullName = user?.FullName ?? "",
                Email = user?.Email ?? "",
                Phone = user?.Phone,
                ProfileImageUrl = user?.ProfileImageUrl,
                LicenseNumber = provider.LicenseNumber,
                Specialty = provider.Specialty,
                FacilityId = provider.FacilityId,
                FacilityName = facility?.Name ?? "",
                IsActive = user?.IsActive ?? false,
                CreatedAt = user?.CreatedAt ?? DateTime.UtcNow
            });
        }

        return result;
    }
}
