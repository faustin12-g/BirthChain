using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;

namespace BirthChain.Infrastructure.Services;

public sealed class ClientService : IClientService
{
    private readonly IClientRepository _clientRepo;
    private readonly IUserRepository _userRepo;
    private readonly IProfileService _profileService;

    public ClientService(
        IClientRepository clientRepo,
        IUserRepository userRepo,
        IProfileService profileService)
    {
        _clientRepo = clientRepo;
        _userRepo = userRepo;
        _profileService = profileService;
    }

    public async Task<ClientDto> CreateAsync(CreateClientDto dto)
    {
        var client = new Client
        {
            FullName = dto.FullName,
            Phone = dto.Phone,
            Email = dto.Email,
            Gender = dto.Gender,
            Address = dto.Address,
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

    public async Task<ClientDto?> GetByUserIdAsync(Guid userId)
    {
        var client = await _clientRepo.GetByUserIdAsync(userId);
        return client is null ? null : ToDto(client);
    }

    public async Task<IReadOnlyList<ClientDto>> GetAllAsync()
    {
        var clients = await _clientRepo.GetAllAsync();
        return clients.Select(ToDto).ToList().AsReadOnly();
    }

    public async Task<IReadOnlyList<ClientDto>> SearchAsync(string query)
    {
        var clients = await _clientRepo.SearchAsync(query);
        return clients.Select(ToDto).ToList().AsReadOnly();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PIN-secured access methods
    // ═══════════════════════════════════════════════════════════════════════

    public async Task<ClientLookupDto?> LookupByQrCodeAsync(string qrCodeId)
    {
        var client = await _clientRepo.GetByQrCodeAsync(qrCodeId);
        if (client is null) return null;

        bool hasPinSet = false;

        // If client has a linked user account, check if they have a PIN
        if (client.UserId.HasValue)
        {
            var user = await _userRepo.GetByIdAsync(client.UserId.Value);
            if (user is not null)
            {
                hasPinSet = !string.IsNullOrEmpty(user.PinHash);
            }
        }

        return new ClientLookupDto
        {
            Id = client.Id,
            FullName = client.FullName,
            QrCodeId = client.QrCodeId,
            HasPinSet = hasPinSet
        };
    }

    public async Task<ClientDto?> GetByQrCodeWithPinAsync(string qrCodeId, string pin)
    {
        var client = await _clientRepo.GetByQrCodeAsync(qrCodeId);
        if (client is null) return null;

        // If client has a linked user account with PIN, verify it
        if (client.UserId.HasValue)
        {
            var user = await _userRepo.GetByIdAsync(client.UserId.Value);
            if (user is not null && !string.IsNullOrEmpty(user.PinHash))
            {
                // Verify PIN using profile service (handles lockout etc.)
                var isValid = await _profileService.VerifyPinAsync(client.UserId.Value, pin);
                if (!isValid) return null;
            }
        }

        return ToDto(client);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Private Helper Methods
    // ═══════════════════════════════════════════════════════════════════════

    private static ClientDto ToDto(Client c) => new()
    {
        Id = c.Id,
        FullName = c.FullName,
        Phone = c.Phone,
        Email = c.Email,
        Gender = c.Gender,
        Address = c.Address,
        DateOfBirth = c.DateOfBirth,
        QrCodeId = c.QrCodeId,
        CreatedAt = c.CreatedAt,
        UserId = c.UserId
    };
}
