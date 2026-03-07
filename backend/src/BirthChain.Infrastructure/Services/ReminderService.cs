using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;

namespace BirthChain.Infrastructure.Services;

public sealed class ReminderService : IReminderService
{
    private readonly IReminderRepository _reminderRepo;
    private readonly IProviderRepository _providerRepo;
    private readonly IClientRepository _clientRepo;
    private readonly IFacilityRepository _facilityRepo;
    private readonly IFcmNotificationService _fcmService;
    private readonly IUserRepository _userRepo;
    private readonly BirthChainDbContext _context;

    public ReminderService(
        IReminderRepository reminderRepo,
        IProviderRepository providerRepo,
        IClientRepository clientRepo,
        IFacilityRepository facilityRepo,
        IFcmNotificationService fcmService,
        IUserRepository userRepo,
        BirthChainDbContext context)
    {
        _reminderRepo = reminderRepo;
        _providerRepo = providerRepo;
        _clientRepo = clientRepo;
        _facilityRepo = facilityRepo;
        _fcmService = fcmService;
        _userRepo = userRepo;
        _context = context;
    }

    public async Task<ReminderDto> CreateAsync(Guid providerUserId, CreateReminderDto dto)
    {
        // Resolve provider from their User Id
        var provider = await _providerRepo.GetByUserIdAsync(providerUserId)
            ?? throw new InvalidOperationException("Provider profile not found for this user.");

        // Validate client exists
        var client = await _clientRepo.GetByIdAsync(dto.ClientId)
            ?? throw new InvalidOperationException($"Client '{dto.ClientId}' not found.");

        // Get facility name
        var facility = await _facilityRepo.GetByIdAsync(provider.FacilityId);
        var facilityName = dto.FacilityName ?? facility?.Name ?? "Unknown Facility";

        var reminder = new Reminder
        {
            ClientId = dto.ClientId,
            ProviderId = provider.Id,
            ReminderType = dto.ReminderType,
            Title = dto.Title,
            Message = dto.Message,
            ScheduledDate = DateTime.SpecifyKind(dto.ScheduledDate, DateTimeKind.Utc),
            NotifyBeforeMinutes = dto.NotifyBeforeMinutes,
            IsRecurring = dto.IsRecurring,
            RecurrencePattern = dto.RecurrencePattern,
            FacilityName = facilityName,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        await _reminderRepo.AddAsync(reminder);
        return ToDto(reminder);
    }

    public async Task<ReminderDto?> GetByIdAsync(Guid id)
    {
        var reminder = await _reminderRepo.GetByIdAsync(id);
        return reminder is null ? null : ToDto(reminder);
    }

    public async Task<IReadOnlyList<ReminderDto>> GetByClientIdAsync(Guid clientId)
    {
        var reminders = await _reminderRepo.GetByClientIdAsync(clientId);
        return reminders.Select(ToDto).ToList().AsReadOnly();
    }

    public async Task<IReadOnlyList<ReminderDto>> GetUpcomingRemindersAsync(Guid clientId, int daysAhead = 7)
    {
        var allUpcoming = await _reminderRepo.GetUpcomingAsync(DateTime.UtcNow, daysAhead);
        return allUpcoming
            .Where(r => r.ClientId == clientId)
            .Select(ToDto)
            .ToList()
            .AsReadOnly();
    }

    public async Task MarkCompletedAsync(Guid reminderId)
    {
        var reminder = await _reminderRepo.GetByIdAsync(reminderId);
        if (reminder is not null)
        {
            reminder.Status = "Completed";
            reminder.CompletedAt = DateTime.UtcNow;
            await _reminderRepo.UpdateAsync(reminder);

            // If recurring, create the next occurrence
            if (reminder.IsRecurring && !string.IsNullOrEmpty(reminder.RecurrencePattern))
            {
                var nextDate = CalculateNextOccurrence(reminder.ScheduledDate, reminder.RecurrencePattern);
                if (nextDate.HasValue)
                {
                    var nextReminder = new Reminder
                    {
                        ClientId = reminder.ClientId,
                        ProviderId = reminder.ProviderId,
                        ReminderType = reminder.ReminderType,
                        Title = reminder.Title,
                        Message = reminder.Message,
                        ScheduledDate = nextDate.Value,
                        NotifyBeforeMinutes = reminder.NotifyBeforeMinutes,
                        IsRecurring = true,
                        RecurrencePattern = reminder.RecurrencePattern,
                        FacilityName = reminder.FacilityName,
                        Status = "Pending",
                        CreatedAt = DateTime.UtcNow
                    };
                    await _reminderRepo.AddAsync(nextReminder);
                }
            }
        }
    }

    public async Task DeleteAsync(Guid reminderId)
    {
        await _reminderRepo.DeleteAsync(reminderId);
    }

    /// <summary>
    /// Processes pending reminders that need notification. Called by background job.
    /// </summary>
    public async Task ProcessPendingRemindersAsync()
    {
        var pendingReminders = await _reminderRepo.GetPendingForNotificationAsync();

        foreach (var reminder in pendingReminders)
        {
            // Send notification to client
            var client = await _clientRepo.GetByIdAsync(reminder.ClientId);
            if (client is not null && !string.IsNullOrEmpty(client.Email))
            {
                var user = await _userRepo.GetByEmailAsync(client.Email);
                if (user is not null && !string.IsNullOrEmpty(user.FcmToken))
                {
                    // Save notification for in-app display
                    var notification = new Notification
                    {
                        UserId = user.Id,
                        Title = reminder.Title,
                        Body = reminder.Message,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.Notifications.Add(notification);
                    await _context.SaveChangesAsync();

                    // Send push notification
                    await _fcmService.SendNotificationAsync(user.FcmToken, reminder.Title, reminder.Message);
                }
            }

            // Mark as sent
            reminder.SentAt = DateTime.UtcNow;
            await _reminderRepo.UpdateAsync(reminder);
        }
    }

    private static DateTime? CalculateNextOccurrence(DateTime current, string pattern)
    {
        return pattern.ToLower() switch
        {
            "daily" => current.AddDays(1),
            "weekly" => current.AddDays(7),
            "biweekly" => current.AddDays(14),
            "monthly" => current.AddMonths(1),
            "quarterly" => current.AddMonths(3),
            _ => null
        };
    }

    private static ReminderDto ToDto(Reminder r) => new()
    {
        Id = r.Id,
        ClientId = r.ClientId,
        ProviderId = r.ProviderId,
        ReminderType = r.ReminderType,
        Title = r.Title,
        Message = r.Message,
        ScheduledDate = r.ScheduledDate,
        NotifyBeforeMinutes = r.NotifyBeforeMinutes,
        IsRecurring = r.IsRecurring,
        RecurrencePattern = r.RecurrencePattern,
        Status = r.Status,
        SentAt = r.SentAt,
        CompletedAt = r.CompletedAt,
        FacilityName = r.FacilityName,
        CreatedAt = r.CreatedAt
    };
}
