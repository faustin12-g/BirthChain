using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IProviderRepository
{
    Task<Provider?> GetByIdAsync(Guid id);
    Task<Provider?> GetByUserIdAsync(Guid userId);
    Task<Provider> AddAsync(Provider provider);
    Task<IReadOnlyList<Provider>> GetAllAsync();
    Task<IReadOnlyList<Provider>> GetByFacilityIdAsync(Guid facilityId);
}
