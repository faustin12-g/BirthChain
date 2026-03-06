using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id);
    Task<User?> GetByEmailAsync(string email);
    Task<User> AddAsync(User user);
    Task UpdateAsync(User user);
    Task DeleteAsync(Guid id);
    Task<IReadOnlyList<User>> GetAllAsync();
    Task<IReadOnlyList<User>> GetByRoleAsync(string role);
    Task<IReadOnlyList<User>> GetByFacilityIdAsync(Guid facilityId);
    Task<int> CountByRoleAsync(string role);
    Task<int> CountActiveAsync();
}
