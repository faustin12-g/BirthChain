using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IRecordRepository
{
    Task<Record> AddAsync(Record record);
    Task<IReadOnlyList<Record>> GetAllAsync();
    Task<IReadOnlyList<Record>> GetByClientIdAsync(Guid clientId);
    Task<IReadOnlyList<Record>> GetByProviderIdAsync(Guid providerId);
    Task<int> CountAsync();
}
