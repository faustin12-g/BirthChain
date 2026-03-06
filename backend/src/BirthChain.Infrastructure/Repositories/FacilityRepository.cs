using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class FacilityRepository : IFacilityRepository
{
    private readonly BirthChainDbContext _db;

    public FacilityRepository(BirthChainDbContext db) => _db = db;

    public async Task<Facility?> GetByIdAsync(Guid id)
        => await _db.Facilities.FindAsync(id);

    public async Task<Facility> AddAsync(Facility facility)
    {
        _db.Facilities.Add(facility);
        await _db.SaveChangesAsync();
        return facility;
    }

    public async Task UpdateAsync(Facility facility)
    {
        _db.Facilities.Update(facility);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var facility = await _db.Facilities.FindAsync(id);
        if (facility is not null)
        {
            _db.Facilities.Remove(facility);
            await _db.SaveChangesAsync();
        }
    }

    public async Task<IReadOnlyList<Facility>> GetAllAsync()
        => await _db.Facilities.OrderBy(f => f.Name).ToListAsync();

    public async Task<IReadOnlyList<Facility>> GetActiveAsync()
        => await _db.Facilities.Where(f => f.IsActive).OrderBy(f => f.Name).ToListAsync();

    public async Task<Facility?> GetByNameAsync(string name)
        => await _db.Facilities.FirstOrDefaultAsync(f => f.Name == name);

    public async Task<int> CountAsync()
        => await _db.Facilities.CountAsync();

    public async Task<int> CountActiveAsync()
        => await _db.Facilities.CountAsync(f => f.IsActive);
}
