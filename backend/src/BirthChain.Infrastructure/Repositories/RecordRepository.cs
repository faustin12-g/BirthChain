using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class RecordRepository : IRecordRepository
{
    private readonly BirthChainDbContext _db;

    public RecordRepository(BirthChainDbContext db) => _db = db;

    public async Task<Record> AddAsync(Record record)
    {
        _db.Records.Add(record);
        await _db.SaveChangesAsync();
        return record;
    }

    public async Task<IReadOnlyList<Record>> GetByClientIdAsync(Guid clientId)
        => await _db.Records
            .Where(r => r.ClientId == clientId)
            .OrderBy(r => r.CreatedAt)
            .ToListAsync();

    public async Task<IReadOnlyList<Record>> GetByProviderIdAsync(Guid providerId)
        => await _db.Records
            .Where(r => r.ProviderId == providerId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();
}
