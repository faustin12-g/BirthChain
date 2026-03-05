using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;

namespace BirthChain.Infrastructure.Services;

public sealed class ActivityLogService : IActivityLogService
{
    private readonly IActivityLogRepository _logRepo;
    private readonly IUserRepository _userRepo;

    public ActivityLogService(IActivityLogRepository logRepo, IUserRepository userRepo)
    {
        _logRepo = logRepo;
        _userRepo = userRepo;
    }

    public async Task LogAsync(Guid userId, string action)
    {
        var log = new ActivityLog
        {
            UserId = userId,
            Action = action,
            Timestamp = DateTime.UtcNow
        };

        await _logRepo.AddAsync(log);
    }

    public async Task<IReadOnlyList<ActivityLogDto>> GetAllAsync()
    {
        var logs = await _logRepo.GetAllAsync();
        return await ToDtos(logs);
    }

    public async Task<IReadOnlyList<ActivityLogDto>> GetByUserIdAsync(Guid userId)
    {
        var logs = await _logRepo.GetByUserIdAsync(userId);
        return await ToDtos(logs);
    }

    private async Task<IReadOnlyList<ActivityLogDto>> ToDtos(IReadOnlyList<ActivityLog> logs)
    {
        var result = new List<ActivityLogDto>();
        // Cache user lookups
        var userCache = new Dictionary<Guid, string>();

        foreach (var log in logs)
        {
            if (!userCache.TryGetValue(log.UserId, out var userName))
            {
                var user = await _userRepo.GetByIdAsync(log.UserId);
                userName = user?.FullName ?? "Unknown";
                userCache[log.UserId] = userName;
            }

            result.Add(new ActivityLogDto
            {
                Id = log.Id,
                UserId = log.UserId,
                UserName = userName,
                Action = log.Action,
                Timestamp = log.Timestamp
            });
        }

        return result.AsReadOnly();
    }
}
