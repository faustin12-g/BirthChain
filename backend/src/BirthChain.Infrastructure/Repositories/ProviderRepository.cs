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

    public async Task UpdateAsync(Provider provider)
    {
        _db.Providers.Update(provider);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var provider = await _db.Providers.FindAsync(id);
        if (provider is not null)
        {
            _db.Providers.Remove(provider);
            await _db.SaveChangesAsync();
        }
    }

    public async Task<IReadOnlyList<Provider>> GetAllAsync()
        => await _db.Providers.ToListAsync();

    public async Task<IReadOnlyList<Provider>> GetByFacilityIdAsync(Guid facilityId)
        => await _db.Providers.Where(p => p.FacilityId == facilityId).ToListAsync();

    public async Task<int> CountAsync()
        => await _db.Providers.CountAsync();

    public async Task<int> CountByFacilityIdAsync(Guid facilityId)
        => await _db.Providers.CountAsync(p => p.FacilityId == facilityId);
}
