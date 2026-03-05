using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IRecordService
{
    Task<RecordDto> CreateAsync(Guid providerUserId, CreateRecordDto dto);
    Task<IReadOnlyList<RecordDto>> GetByClientIdAsync(Guid clientId);
}
