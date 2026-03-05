using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class ProviderRepository : IProviderRepository
{
    private readonly BirthChainDbContext _db;

    public ProviderRepository(BirthChainDbContext db) => _db = db;

    public async Task<Provider?> GetByIdAsync(Guid id)
        => await _db.Providers.FindAsync(id);

    public async Task<Provider?> GetByUserIdAsync(Guid userId)
        => await _db.Providers.FirstOrDefaultAsync(p => p.UserId == userId);

    public async Task<Provider> AddAsync(Provider provider)
    {
        _db.Providers.Add(provider);
        await _db.SaveChangesAsync();
        return provider;
    }

    public async Task<IReadOnlyList<Provider>> GetAllAsync()
        => await _db.Providers.ToListAsync();
}
