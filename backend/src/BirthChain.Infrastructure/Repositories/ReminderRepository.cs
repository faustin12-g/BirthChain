using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class ReminderRepository : IReminderRepository
{
    private readonly BirthChainDbContext _db;

    public ReminderRepository(BirthChainDbContext db) => _db = db;

    public async Task<Reminder> AddAsync(Reminder reminder)
    {
        _db.Reminders.Add(reminder);
        await _db.SaveChangesAsync();
        return reminder;
    }

    public async Task<Reminder?> GetByIdAsync(Guid id)
        => await _db.Reminders.FindAsync(id);

    public async Task<IReadOnlyList<Reminder>> GetByClientIdAsync(Guid clientId)
        => await _db.Reminders
            .Where(r => r.ClientId == clientId)
            .OrderBy(r => r.ScheduledDate)
            .ToListAsync();

    public async Task<IReadOnlyList<Reminder>> GetUpcomingAsync(DateTime fromDate, int daysAhead = 7)
    {
        var toDate = fromDate.AddDays(daysAhead);
        return await _db.Reminders
            .Where(r => r.ScheduledDate >= fromDate && r.ScheduledDate <= toDate)
            .Where(r => r.Status == "Pending")
            .OrderBy(r => r.ScheduledDate)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<Reminder>> GetPendingForNotificationAsync()
    {
        var now = DateTime.UtcNow;
        return await _db.Reminders
            .Where(r => r.Status == "Pending")
            .Where(r => r.ScheduledDate.AddMinutes(-r.NotifyBeforeMinutes) <= now)
            .Where(r => r.SentAt == null)
            .OrderBy(r => r.ScheduledDate)
            .ToListAsync();
    }

    public async Task UpdateAsync(Reminder reminder)
    {
        _db.Reminders.Update(reminder);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var reminder = await _db.Reminders.FindAsync(id);
        if (reminder is not null)
        {
            _db.Reminders.Remove(reminder);
            await _db.SaveChangesAsync();
        }
    }
}
