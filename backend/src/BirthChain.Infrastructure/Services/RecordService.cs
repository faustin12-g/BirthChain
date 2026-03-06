using System.Text.Json;
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
    private readonly IFacilityRepository _facilityRepo;
    private readonly IActivityLogService _activityLog;
    private readonly IEmailService _emailService;

    public RecordService(
        IRecordRepository recordRepo,
        IProviderRepository providerRepo,
        IClientRepository clientRepo,
        IUserRepository userRepo,
        IFacilityRepository facilityRepo,
        IActivityLogService activityLog,
        IEmailService emailService)
    {
        _recordRepo = recordRepo;
        _providerRepo = providerRepo;
        _clientRepo = clientRepo;
        _userRepo = userRepo;
        _facilityRepo = facilityRepo;
        _activityLog = activityLog;
        _emailService = emailService;
    }

    public async Task<RecordDto> CreateAsync(Guid providerUserId, CreateRecordDto dto)
    {
        // Resolve provider from their User Id
        var provider = await _providerRepo.GetByUserIdAsync(providerUserId)
            ?? throw new InvalidOperationException("Provider profile not found for this user.");

        // Validate client exists
        var client = await _clientRepo.GetByIdAsync(dto.ClientId)
            ?? throw new InvalidOperationException($"Client '{dto.ClientId}' not found.");

        // Auto-inject facility name and current date into the description JSON
        var description = AutoPopulateDescription(dto.Description, provider);

        var record = new Record
        {
            ClientId = dto.ClientId,
            ProviderId = provider.Id,
            Description = description,
            CreatedAt = DateTime.UtcNow
        };

        await _recordRepo.AddAsync(record);

        // Audit trail
        await _activityLog.LogAsync(providerUserId, $"Created record for client {client.FullName}");

        var user = await _userRepo.GetByIdAsync(provider.UserId);

        // Send email notification to the patient
        if (!string.IsNullOrWhiteSpace(client.Email))
        {
            var facility = await _facilityRepo.GetByIdAsync(provider.FacilityId);
            var facilityName = facility?.Name ?? "Unknown Facility";
            _ = Task.Run(async () =>
            {
                try
                {
                    await _emailService.SendRecordAddedEmailAsync(
                        client.Email,
                        client.FullName,
                        client.QrCodeId,
                        user?.FullName ?? "Provider",
                        facilityName,
                        record.Description,
                        record.CreatedAt);
                }
                catch { /* Don't fail record creation if email fails */ }
            });
        }

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

    /// <summary>
    /// Parses the JSON description and overrides facility + date fields
    /// with the provider's assigned facility name and current UTC date.
    /// </summary>
    private string AutoPopulateDescription(string description, Provider provider)
    {
        try
        {
            var doc = JsonSerializer.Deserialize<Dictionary<string, object>>(description);
            if (doc is not null)
            {
                // Load facility name from provider's assigned facility
                var facility = _facilityRepo.GetByIdAsync(provider.FacilityId).Result;
                doc["facility"] = facility?.Name ?? "";
                doc["date"] = DateTime.UtcNow.ToString("yyyy-MM-dd");
                return JsonSerializer.Serialize(doc);
            }
        }
        catch { /* not JSON – return as-is */ }

        return description;
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
