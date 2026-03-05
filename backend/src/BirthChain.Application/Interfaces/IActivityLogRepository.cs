using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IActivityLogRepository
{
    Task AddAsync(ActivityLog log);
    Task<IReadOnlyList<ActivityLog>> GetAllAsync();
    Task<IReadOnlyList<ActivityLog>> GetByUserIdAsync(Guid userId);
}
