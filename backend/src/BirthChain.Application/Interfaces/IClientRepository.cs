using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IClientRepository
{
    Task<Client> AddAsync(Client client);
    Task<Client?> GetByIdAsync(Guid id);
    Task<Client?> GetByQrCodeAsync(string qrCodeId);
    Task<Client?> GetByUserIdAsync(Guid userId);
    Task<Client?> GetByEmailAsync(string email);
    Task UpdateAsync(Client client);
    Task<IReadOnlyList<Client>> GetAllAsync();
    Task<IReadOnlyList<Client>> SearchAsync(string query);
}
