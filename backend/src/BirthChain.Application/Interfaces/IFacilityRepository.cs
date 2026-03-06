using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IFacilityRepository
{
    Task<Facility?> GetByIdAsync(Guid id);
    Task<Facility> AddAsync(Facility facility);
    Task<IReadOnlyList<Facility>> GetAllAsync();
    Task<Facility?> GetByNameAsync(string name);
}
