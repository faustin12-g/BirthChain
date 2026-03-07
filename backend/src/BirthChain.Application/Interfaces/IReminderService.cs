using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IReminderService
{
    Task<ReminderDto> CreateAsync(Guid providerUserId, CreateReminderDto dto);
    Task<ReminderDto?> GetByIdAsync(Guid id);
    Task<IReadOnlyList<ReminderDto>> GetByClientIdAsync(Guid clientId);
    Task<IReadOnlyList<ReminderDto>> GetUpcomingRemindersAsync(Guid clientId, int daysAhead = 7);
    Task MarkCompletedAsync(Guid reminderId);
    Task DeleteAsync(Guid reminderId);
    Task ProcessPendingRemindersAsync(); // For background job to send notifications
}
