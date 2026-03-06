using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IAdminService
{
    // ══════════════════════════════════════════════════════════════════════════════
    // DASHBOARD & STATISTICS
    // ══════════════════════════════════════════════════════════════════════════════
    Task<DashboardStatsDto> GetDashboardStatsAsync();

    // ══════════════════════════════════════════════════════════════════════════════
    // FACILITY MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════
    Task<IReadOnlyList<FacilityDetailDto>> GetAllFacilitiesAsync();
    Task<FacilityDetailDto?> GetFacilityByIdAsync(Guid id);
    Task<FacilityDetailDto> UpdateFacilityAsync(Guid id, UpdateFacilityDto dto);
    Task ActivateFacilityAsync(Guid id);
    Task DeactivateFacilityAsync(Guid id);
    Task DeleteFacilityAsync(Guid id);

    // ══════════════════════════════════════════════════════════════════════════════
    // USER MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════
    Task<IReadOnlyList<UserDetailDto>> GetAllUsersAsync();
    Task<IReadOnlyList<UserDetailDto>> GetUsersByRoleAsync(string role);
    Task<UserDetailDto?> GetUserByIdAsync(Guid id);
    Task<UserDetailDto> UpdateUserAsync(Guid id, AdminUpdateUserDto dto);
    Task ActivateUserAsync(Guid id);
    Task DeactivateUserAsync(Guid id);
    Task DeleteUserAsync(Guid id);

    // ══════════════════════════════════════════════════════════════════════════════
    // PROVIDER MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════════
    Task<IReadOnlyList<ProviderDetailDto>> GetAllProvidersAsync();
    Task<IReadOnlyList<ProviderDetailDto>> GetProvidersByFacilityAsync(Guid facilityId);
    Task<ProviderDetailDto?> GetProviderByIdAsync(Guid id);
    Task<ProviderDetailDto> UpdateProviderAsync(Guid id, UpdateProviderDto dto);
    Task ActivateProviderAsync(Guid id);
    Task DeactivateProviderAsync(Guid id);
    Task DeleteProviderAsync(Guid id);
}
