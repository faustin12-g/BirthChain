using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IActivityLogService
{
    Task LogAsync(Guid userId, string action);
    Task<IReadOnlyList<ActivityLogDto>> GetAllAsync();
    Task<IReadOnlyList<ActivityLogDto>> GetByUserIdAsync(Guid userId);
}
