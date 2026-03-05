using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IClientRepository
{
    Task<Client> AddAsync(Client client);
    Task<Client?> GetByIdAsync(Guid id);
    Task<Client?> GetByQrCodeAsync(string qrCodeId);
    Task<IReadOnlyList<Client>> GetAllAsync();
}
