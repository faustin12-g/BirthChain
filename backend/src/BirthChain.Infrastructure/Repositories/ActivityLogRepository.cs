using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class ActivityLogRepository : IActivityLogRepository
{
    private readonly BirthChainDbContext _db;

    public ActivityLogRepository(BirthChainDbContext db) => _db = db;

    public async Task AddAsync(ActivityLog log)
    {
        _db.ActivityLogs.Add(log);
        await _db.SaveChangesAsync();
    }

    public async Task<IReadOnlyList<ActivityLog>> GetAllAsync()
        => await _db.ActivityLogs
            .OrderByDescending(a => a.Timestamp)
            .ToListAsync();

    public async Task<IReadOnlyList<ActivityLog>> GetByUserIdAsync(Guid userId)
        => await _db.ActivityLogs
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.Timestamp)
            .ToListAsync();
}
