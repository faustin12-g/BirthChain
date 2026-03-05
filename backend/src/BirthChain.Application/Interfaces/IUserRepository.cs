using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id);
    Task<User?> GetByEmailAsync(string email);
    Task<User> AddAsync(User user);
    Task<IReadOnlyList<User>> GetAllAsync();
}
