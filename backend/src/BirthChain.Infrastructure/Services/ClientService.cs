using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;

namespace BirthChain.Infrastructure.Services;

public sealed class ClientService : IClientService
{
    private readonly IClientRepository _clientRepo;

    public ClientService(IClientRepository clientRepo) => _clientRepo = clientRepo;

    public async Task<ClientDto> CreateAsync(CreateClientDto dto)
    {
        var client = new Client
        {
            FullName = dto.FullName,
            Phone = dto.Phone,
            DateOfBirth = DateTime.SpecifyKind(dto.DateOfBirth, DateTimeKind.Utc),
            QrCodeId = $"BC-{Guid.NewGuid().ToString("N")[..8].ToUpper()}",
            CreatedAt = DateTime.UtcNow
        };

        await _clientRepo.AddAsync(client);
        return ToDto(client);
    }

    public async Task<ClientDto?> GetByIdAsync(Guid id)
    {
        var client = await _clientRepo.GetByIdAsync(id);
        return client is null ? null : ToDto(client);
    }

    public async Task<ClientDto?> GetByQrCodeAsync(string qrCodeId)
    {
        var client = await _clientRepo.GetByQrCodeAsync(qrCodeId);
        return client is null ? null : ToDto(client);
    }

    public async Task<IReadOnlyList<ClientDto>> GetAllAsync()
    {
        var clients = await _clientRepo.GetAllAsync();
        return clients.Select(ToDto).ToList().AsReadOnly();
    }

    private static ClientDto ToDto(Client c) => new()
    {
        Id = c.Id,
        FullName = c.FullName,
        Phone = c.Phone,
        DateOfBirth = c.DateOfBirth,
        QrCodeId = c.QrCodeId,
        CreatedAt = c.CreatedAt
    };
}
