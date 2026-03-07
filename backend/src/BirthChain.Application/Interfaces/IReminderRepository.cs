using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IReminderRepository
{
    Task<Reminder> AddAsync(Reminder reminder);
    Task<Reminder?> GetByIdAsync(Guid id);
    Task<IReadOnlyList<Reminder>> GetByClientIdAsync(Guid clientId);
    Task<IReadOnlyList<Reminder>> GetUpcomingAsync(DateTime fromDate, int daysAhead = 7);
    Task<IReadOnlyList<Reminder>> GetPendingForNotificationAsync();
    Task UpdateAsync(Reminder reminder);
    Task DeleteAsync(Guid id);
}
