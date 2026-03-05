using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IClientService
{
    Task<ClientDto> CreateAsync(CreateClientDto dto);
    Task<ClientDto?> GetByIdAsync(Guid id);
    Task<ClientDto?> GetByQrCodeAsync(string qrCodeId);
    Task<IReadOnlyList<ClientDto>> GetAllAsync();
}
