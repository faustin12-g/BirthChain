using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;

namespace BirthChain.Infrastructure.Services;

public sealed class RecordService : IRecordService
{
    private readonly IRecordRepository _recordRepo;
    private readonly IProviderRepository _providerRepo;
    private readonly IClientRepository _clientRepo;
    private readonly IUserRepository _userRepo;
    private readonly IActivityLogService _activityLog;

    public RecordService(
        IRecordRepository recordRepo,
        IProviderRepository providerRepo,
        IClientRepository clientRepo,
        IUserRepository userRepo,
        IActivityLogService activityLog)
    {
        _recordRepo = recordRepo;
        _providerRepo = providerRepo;
        _clientRepo = clientRepo;
        _userRepo = userRepo;
        _activityLog = activityLog;
    }

    public async Task<RecordDto> CreateAsync(Guid providerUserId, CreateRecordDto dto)
    {
        // Resolve provider from their User Id
        var provider = await _providerRepo.GetByUserIdAsync(providerUserId)
            ?? throw new InvalidOperationException("Provider profile not found for this user.");

        // Validate client exists
        var client = await _clientRepo.GetByIdAsync(dto.ClientId)
            ?? throw new InvalidOperationException($"Client '{dto.ClientId}' not found.");

        var record = new Record
        {
            ClientId = dto.ClientId,
            ProviderId = provider.Id,
            Description = dto.Description,
            CreatedAt = DateTime.UtcNow
        };

        await _recordRepo.AddAsync(record);

        // Audit trail
        await _activityLog.LogAsync(providerUserId, $"Created record for client {client.FullName}");

        var user = await _userRepo.GetByIdAsync(provider.UserId);

        return new RecordDto
        {
            Id = record.Id,
            ClientId = record.ClientId,
            ProviderId = record.ProviderId,
            Description = record.Description,
            CreatedAt = record.CreatedAt,
            ClientName = client.FullName,
            ProviderName = user?.FullName ?? ""
        };
    }

    public async Task<IReadOnlyList<RecordDto>> GetByClientIdAsync(Guid clientId)
    {
        var records = await _recordRepo.GetByClientIdAsync(clientId);
        var client = await _clientRepo.GetByIdAsync(clientId);
        var result = new List<RecordDto>();

        foreach (var r in records)
        {
            // Record.ProviderId references Provider.Id
            var provider = await _providerRepo.GetByIdAsync(r.ProviderId);
            string providerName = "";
            if (provider is not null)
            {
                var user = await _userRepo.GetByIdAsync(provider.UserId);
                providerName = user?.FullName ?? "";
            }

            result.Add(new RecordDto
            {
                Id = r.Id,
                ClientId = r.ClientId,
                ProviderId = r.ProviderId,
                Description = r.Description,
                CreatedAt = r.CreatedAt,
                ClientName = client?.FullName ?? "",
                ProviderName = providerName
            });
        }

        return result.AsReadOnly();
    }
}
