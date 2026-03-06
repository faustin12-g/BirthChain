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

    public async Task<IReadOnlyList<Facility>> GetAllAsync()
        => await _db.Facilities.OrderBy(f => f.Name).ToListAsync();

    public async Task<Facility?> GetByNameAsync(string name)
        => await _db.Facilities.FirstOrDefaultAsync(f => f.Name == name);
}
