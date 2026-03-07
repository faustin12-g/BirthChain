using System.Text.Json;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;

namespace BirthChain.Infrastructure.Services;

public sealed class RecordService : IRecordService
{
    private readonly IRecordRepository _recordRepo;
    private readonly IProviderRepository _providerRepo;
    private readonly IClientRepository _clientRepo;
    private readonly IUserRepository _userRepo;
    private readonly IFacilityRepository _facilityRepo;
    private readonly IActivityLogService _activityLog;
    private readonly IEmailQueue _emailQueue;
    private readonly IFcmNotificationService _fcmService;
    private readonly BirthChainDbContext _context;

    public RecordService(
        IRecordRepository recordRepo,
        IProviderRepository providerRepo,
        IClientRepository clientRepo,
        IUserRepository userRepo,
        IFacilityRepository facilityRepo,
        IActivityLogService activityLog,
        IEmailQueue emailQueue,
        IFcmNotificationService fcmService,
        BirthChainDbContext context)
    {
        _recordRepo = recordRepo;
        _providerRepo = providerRepo;
        _clientRepo = clientRepo;
        _userRepo = userRepo;
        _facilityRepo = facilityRepo;
        _activityLog = activityLog;
        _emailQueue = emailQueue;
        _fcmService = fcmService;
        _context = context;
    }

    public async Task<RecordDto> CreateAsync(Guid providerUserId, CreateRecordDto dto)
    {
        // Resolve provider from their User Id
        var provider = await _providerRepo.GetByUserIdAsync(providerUserId)
            ?? throw new InvalidOperationException("Provider profile not found for this user.");

        // Validate client exists
        var client = await _clientRepo.GetByIdAsync(dto.ClientId)
            ?? throw new InvalidOperationException($"Client '{dto.ClientId}' not found.");

        // Get facility name
        var facility = await _facilityRepo.GetByIdAsync(provider.FacilityId);
        var facilityName = facility?.Name ?? "Unknown Facility";

        // Build backward-compatible Description JSON from new fields
        var descriptionJson = BuildDescriptionJson(dto, facilityName);

        var record = new Record
        {
            ClientId = dto.ClientId,
            ProviderId = provider.Id,
            CreatedAt = DateTime.UtcNow,

            // Record Classification
            RecordType = dto.RecordType,
            VisitDate = dto.VisitDate.HasValue 
                ? DateTime.SpecifyKind(dto.VisitDate.Value, DateTimeKind.Utc) 
                : DateTime.UtcNow,
            FacilityName = facilityName,

            // Clinical Information
            ChiefComplaint = dto.ChiefComplaint,
            Symptoms = dto.Symptoms,
            Examination = dto.Examination ?? "",
            Diagnosis = dto.Diagnosis,
            SecondaryDiagnoses = dto.SecondaryDiagnoses,
            Treatment = dto.Treatment ?? "",

            // Vital Signs
            BloodPressure = dto.BloodPressure,
            PulseRate = dto.PulseRate,
            Temperature = dto.Temperature,
            Weight = dto.Weight,
            Height = dto.Height,
            OxygenSaturation = dto.OxygenSaturation,
            RespiratoryRate = dto.RespiratoryRate,

            // Maternal Health
            GestationalWeeks = dto.GestationalWeeks,
            GestationalDays = dto.GestationalDays,
            FundalHeight = dto.FundalHeight,
            FetalHeartRate = dto.FetalHeartRate,
            FetalPresentation = dto.FetalPresentation,
            FetalMovement = dto.FetalMovement,
            DeliveryMode = dto.DeliveryMode,
            BirthOutcome = dto.BirthOutcome,
            BabyWeightGrams = dto.BabyWeightGrams,
            ApgarScore1Min = dto.ApgarScore1Min,
            ApgarScore5Min = dto.ApgarScore5Min,

            // Medications & Lab Tests
            Medications = dto.Medications,
            LabTests = dto.LabTests,
            Immunizations = dto.Immunizations,

            // Plan & Follow-up
            CareInstructions = dto.CareInstructions,
            FollowUpRequired = dto.FollowUpRequired,
            FollowUpDate = dto.FollowUpDate.HasValue
                ? DateTime.SpecifyKind(dto.FollowUpDate.Value, DateTimeKind.Utc)
                : null,
            ReferralTo = dto.ReferralTo,
            Notes = dto.Notes,

            // Legacy field
            Description = descriptionJson
        };

        await _recordRepo.AddAsync(record);

        // Audit trail
        await _activityLog.LogAsync(providerUserId, $"Created {dto.RecordType} record for client {client.FullName}");

        var user = await _userRepo.GetByIdAsync(provider.UserId);
        var providerName = user?.FullName ?? "Provider";

        // Send push notification to the patient (if they have a user account with FCM token)
        await SendNotificationToClientAsync(
            client,
            "New Health Record Added",
            $"A new {dto.RecordType} record has been created by {providerName} at {facilityName}."
        );

        // Send email notification to the patient
        if (!string.IsNullOrWhiteSpace(client.Email))
        {
            var clientEmail = client.Email;
            var clientName = client.FullName;
            var qrCodeId = client.QrCodeId;
            var recordDescription = record.Description;
            var createdAt = record.CreatedAt;

            _emailQueue.QueueEmail(async svc => await svc.SendRecordAddedEmailAsync(
                clientEmail, clientName, qrCodeId, providerName, facilityName, recordDescription, createdAt));
        }

        return ToDto(record, client.FullName, providerName);
    }

    /// <summary>
    /// Builds backward-compatible JSON description from structured fields
    /// </summary>
    private static string BuildDescriptionJson(CreateRecordDto dto, string facilityName)
    {
        var doc = new Dictionary<string, object?>
        {
            ["facility"] = facilityName,
            ["date"] = DateTime.UtcNow.ToString("yyyy-MM-dd"),
            ["diagnosis"] = dto.Diagnosis,
            ["symptoms"] = dto.Symptoms,
            ["medication"] = dto.Medications,
            ["labTests"] = dto.LabTests,
            ["notes"] = dto.Notes
        };
        return JsonSerializer.Serialize(doc);
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

            result.Add(ToDto(r, client?.FullName ?? "", providerName));
        }

        return result.AsReadOnly();
    }

    private static RecordDto ToDto(Record r, string clientName, string providerName) => new()
    {
        Id = r.Id,
        ClientId = r.ClientId,
        ProviderId = r.ProviderId,
        CreatedAt = r.CreatedAt,
        ClientName = clientName,
        ProviderName = providerName,

        // Record Classification
        RecordType = r.RecordType,
        VisitDate = r.VisitDate,
        FacilityName = r.FacilityName,

        // Clinical Information
        ChiefComplaint = r.ChiefComplaint,
        Symptoms = r.Symptoms,
        Examination = r.Examination,
        Diagnosis = r.Diagnosis,
        SecondaryDiagnoses = r.SecondaryDiagnoses,
        Treatment = r.Treatment,

        // Vital Signs
        BloodPressure = r.BloodPressure,
        PulseRate = r.PulseRate,
        Temperature = r.Temperature,
        Weight = r.Weight,
        Height = r.Height,
        OxygenSaturation = r.OxygenSaturation,
        RespiratoryRate = r.RespiratoryRate,

        // Maternal Health
        GestationalWeeks = r.GestationalWeeks,
        GestationalDays = r.GestationalDays,
        FundalHeight = r.FundalHeight,
        FetalHeartRate = r.FetalHeartRate,
        FetalPresentation = r.FetalPresentation,
        FetalMovement = r.FetalMovement,
        DeliveryMode = r.DeliveryMode,
        BirthOutcome = r.BirthOutcome,
        BabyWeightGrams = r.BabyWeightGrams,
        ApgarScore1Min = r.ApgarScore1Min,
        ApgarScore5Min = r.ApgarScore5Min,

        // Medications & Lab Tests
        Medications = r.Medications,
        LabTests = r.LabTests,
        Immunizations = r.Immunizations,

        // Plan & Follow-up
        CareInstructions = r.CareInstructions,
        FollowUpRequired = r.FollowUpRequired,
        FollowUpDate = r.FollowUpDate,
        ReferralTo = r.ReferralTo,
        Notes = r.Notes,

        // Legacy
        Description = r.Description
    };

    private async Task SendNotificationToClientAsync(Client client, string title, string body)
    {
        // Find user account linked to this client's email
        if (string.IsNullOrEmpty(client.Email)) return;

        var user = await _userRepo.GetByEmailAsync(client.Email);
        if (user == null || string.IsNullOrEmpty(user.FcmToken)) return;

        // Save notification for in-app display
        var notification = new Notification
        {
            UserId = user.Id,
            Title = title,
            Body = body,
            CreatedAt = DateTime.UtcNow
        };
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        // Send push notification
        await _fcmService.SendNotificationAsync(user.FcmToken, title, body);
    }
}
