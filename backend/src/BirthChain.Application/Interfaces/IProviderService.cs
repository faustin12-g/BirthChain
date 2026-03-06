using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IProviderService
{
    Task<ProviderDto> CreateAsync(CreateProviderDto dto);
    Task<IReadOnlyList<ProviderDto>> GetAllAsync();
    Task<ProviderDto?> GetByUserIdAsync(Guid userId);
    Task<IReadOnlyList<ProviderDto>> GetByFacilityIdAsync(Guid facilityId);
}
