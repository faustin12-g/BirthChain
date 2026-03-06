using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IClientService
{
    Task<ClientDto> CreateAsync(CreateClientDto dto);
    Task<ClientDto?> GetByIdAsync(Guid id);
    Task<ClientDto?> GetByQrCodeAsync(string qrCodeId);
    Task<ClientDto?> GetByUserIdAsync(Guid userId);
    Task<IReadOnlyList<ClientDto>> GetAllAsync();
    Task<IReadOnlyList<ClientDto>> SearchAsync(string query);

    // PIN-secured access methods

    /// <summary>Look up client by QR code (returns limited info + hasPinSet)</summary>
    Task<ClientLookupDto?> LookupByQrCodeAsync(string qrCodeId);

    /// <summary>Get full client data after PIN verification</summary>
    Task<ClientDto?> GetByQrCodeWithPinAsync(string qrCodeId, string pin);
}
