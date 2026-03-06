using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IFacilityRepository
{
    Task<Facility?> GetByIdAsync(Guid id);
    Task<Facility> AddAsync(Facility facility);
    Task UpdateAsync(Facility facility);
    Task DeleteAsync(Guid id);
    Task<IReadOnlyList<Facility>> GetAllAsync();
    Task<IReadOnlyList<Facility>> GetActiveAsync();
    Task<Facility?> GetByNameAsync(string name);
    Task<int> CountAsync();
    Task<int> CountActiveAsync();
}
