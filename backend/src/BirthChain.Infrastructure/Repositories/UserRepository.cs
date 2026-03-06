using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class UserRepository : IUserRepository
{
    private readonly BirthChainDbContext _db;

    public UserRepository(BirthChainDbContext db) => _db = db;

    public async Task<User?> GetByIdAsync(Guid id)
        => await _db.Users.FindAsync(id);

    public async Task<User?> GetByEmailAsync(string email)
        => await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

    public async Task<User> AddAsync(User user)
    {
        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return user;
    }

    public async Task UpdateAsync(User user)
    {
        _db.Users.Update(user);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var user = await _db.Users.FindAsync(id);
        if (user is not null)
        {
            _db.Users.Remove(user);
            await _db.SaveChangesAsync();
        }
    }

    public async Task<IReadOnlyList<User>> GetAllAsync()
        => await _db.Users.OrderBy(u => u.FullName).ToListAsync();

    public async Task<IReadOnlyList<User>> GetByRoleAsync(string role)
        => await _db.Users.Where(u => u.Role == role).OrderBy(u => u.FullName).ToListAsync();

    public async Task<IReadOnlyList<User>> GetByFacilityIdAsync(Guid facilityId)
        => await _db.Users.Where(u => u.FacilityId == facilityId).OrderBy(u => u.FullName).ToListAsync();

    public async Task<int> CountByRoleAsync(string role)
        => await _db.Users.CountAsync(u => u.Role == role);

    public async Task<int> CountActiveAsync()
        => await _db.Users.CountAsync(u => u.IsActive);
}
