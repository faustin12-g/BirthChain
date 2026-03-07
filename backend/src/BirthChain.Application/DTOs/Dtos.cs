namespace BirthChain.Application.DTOs;

// ── Auth ──

public record LoginRequestDto
{
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
}

public record LoginResponseDto
{
    public string Token { get; init; } = string.Empty;
    public Guid UserId { get; init; }
    public string Email { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public DateTime ExpiresAt { get; init; }
    public Guid? FacilityId { get; init; }
    public string FacilityName { get; init; } = string.Empty;
}

public record RegisterPatientDto
{
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Gender { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
}

// ── User ──

public record UserDto
{
    public Guid Id { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public record CreateUserDto
{
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string Role { get; init; } = "Provider";
}

// ── Provider ──

public record ProviderDto
{
    public Guid Id { get; init; }
    public Guid UserId { get; init; }
    public string LicenseNumber { get; init; } = string.Empty;
    public Guid FacilityId { get; init; }
    public string FacilityName { get; init; } = string.Empty;
    public string Specialty { get; init; } = string.Empty;

    // Joined from User
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
}

public record CreateProviderDto
{
    // User fields
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;

    // Provider profile fields
    public string LicenseNumber { get; init; } = string.Empty;
    public Guid FacilityId { get; init; }
    public string Specialty { get; init; } = string.Empty;
}

// ── Facility ──

public record FacilityDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
}

public record CreateFacilityDto
{
    public string Name { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
}

// ── FacilityAdmin ──

public record CreateFacilityAdminDto
{
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public Guid FacilityId { get; init; }
}

// ── Client ──

public record ClientDto
{
    public Guid Id { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Gender { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
    public string QrCodeId { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
    public Guid? UserId { get; init; }

    // Medical Profile
    public string PatientCategory { get; init; } = "General";
    public string? BloodType { get; init; }
    public string? Allergies { get; init; }
    public string? ChronicConditions { get; init; }
    public string? EmergencyContactName { get; init; }
    public string? EmergencyContactPhone { get; init; }

    // Maternal Health
    public bool IsPregnant { get; init; }
    public DateTime? LastMenstrualPeriod { get; init; }
    public DateTime? ExpectedDeliveryDate { get; init; }
    public int? Gravida { get; init; }
    public int? Parity { get; init; }
    public bool IsHighRiskPregnancy { get; init; }
    public string? HighRiskFactors { get; init; }
}

/// <summary>Limited client info returned when looking up by QR code (before PIN verification)</summary>
public record ClientLookupDto
{
    public Guid Id { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string QrCodeId { get; init; } = string.Empty;
    public bool HasPinSet { get; init; }
    public bool RequiresPin => HasPinSet;
    public string PatientCategory { get; init; } = "General";
    public bool IsPregnant { get; init; }
}

public record CreateClientDto
{
    public string FullName { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Gender { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }

    // Medical Profile
    public string PatientCategory { get; init; } = "General";
    public string? BloodType { get; init; }
    public string? Allergies { get; init; }
    public string? ChronicConditions { get; init; }
    public string? EmergencyContactName { get; init; }
    public string? EmergencyContactPhone { get; init; }

    // Maternal Health (for pregnant women)
    public bool IsPregnant { get; init; }
    public DateTime? LastMenstrualPeriod { get; init; }
    public DateTime? ExpectedDeliveryDate { get; init; }
    public int? Gravida { get; init; }
    public int? Parity { get; init; }
    public bool IsHighRiskPregnancy { get; init; }
    public string? HighRiskFactors { get; init; }
}

public record UpdateClientDto
{
    public string? FullName { get; init; }
    public string? Phone { get; init; }
    public string? Address { get; init; }
    public string? PatientCategory { get; init; }
    public string? BloodType { get; init; }
    public string? Allergies { get; init; }
    public string? ChronicConditions { get; init; }
    public string? EmergencyContactName { get; init; }
    public string? EmergencyContactPhone { get; init; }
    public bool? IsPregnant { get; init; }
    public DateTime? LastMenstrualPeriod { get; init; }
    public DateTime? ExpectedDeliveryDate { get; init; }
    public int? Gravida { get; init; }
    public int? Parity { get; init; }
    public bool? IsHighRiskPregnancy { get; init; }
    public string? HighRiskFactors { get; init; }
}

// ── Record ──

public record RecordDto
{
    public Guid Id { get; init; }
    public Guid ClientId { get; init; }
    public Guid ProviderId { get; init; }
    public DateTime CreatedAt { get; init; }

    // Joined display names
    public string ClientName { get; init; } = string.Empty;
    public string ProviderName { get; init; } = string.Empty;

    // Record Classification
    public string RecordType { get; init; } = "Consultation";
    public DateTime VisitDate { get; init; }
    public string FacilityName { get; init; } = string.Empty;

    // Clinical Information
    public string ChiefComplaint { get; init; } = string.Empty;
    public string Symptoms { get; init; } = string.Empty;
    public string Examination { get; init; } = string.Empty;
    public string Diagnosis { get; init; } = string.Empty;
    public string? SecondaryDiagnoses { get; init; }
    public string Treatment { get; init; } = string.Empty;

    // Vital Signs
    public string? BloodPressure { get; init; }
    public int? PulseRate { get; init; }
    public decimal? Temperature { get; init; }
    public decimal? Weight { get; init; }
    public decimal? Height { get; init; }
    public int? OxygenSaturation { get; init; }
    public int? RespiratoryRate { get; init; }

    // Maternal Health Fields
    public int? GestationalWeeks { get; init; }
    public int? GestationalDays { get; init; }
    public decimal? FundalHeight { get; init; }
    public int? FetalHeartRate { get; init; }
    public string? FetalPresentation { get; init; }
    public string? FetalMovement { get; init; }
    public string? DeliveryMode { get; init; }
    public string? BirthOutcome { get; init; }
    public int? BabyWeightGrams { get; init; }
    public int? ApgarScore1Min { get; init; }
    public int? ApgarScore5Min { get; init; }

    // Medications & Lab Tests
    public string? Medications { get; init; }
    public string? LabTests { get; init; }
    public string? Immunizations { get; init; }

    // Plan & Follow-up
    public string? CareInstructions { get; init; }
    public bool FollowUpRequired { get; init; }
    public DateTime? FollowUpDate { get; init; }
    public string? ReferralTo { get; init; }
    public string? Notes { get; init; }

    // Legacy field
    public string Description { get; init; } = string.Empty;
}

public record CreateRecordDto
{
    public Guid ClientId { get; init; }
    
    // Record Classification
    public string RecordType { get; init; } = "Consultation";
    public DateTime? VisitDate { get; init; }

    // Clinical Information
    public string ChiefComplaint { get; init; } = string.Empty;
    public string Symptoms { get; init; } = string.Empty;
    public string? Examination { get; init; }
    public string Diagnosis { get; init; } = string.Empty;
    public string? SecondaryDiagnoses { get; init; }
    public string? Treatment { get; init; }

    // Vital Signs
    public string? BloodPressure { get; init; }
    public int? PulseRate { get; init; }
    public decimal? Temperature { get; init; }
    public decimal? Weight { get; init; }
    public decimal? Height { get; init; }
    public int? OxygenSaturation { get; init; }
    public int? RespiratoryRate { get; init; }

    // Maternal Health Fields
    public int? GestationalWeeks { get; init; }
    public int? GestationalDays { get; init; }
    public decimal? FundalHeight { get; init; }
    public int? FetalHeartRate { get; init; }
    public string? FetalPresentation { get; init; }
    public string? FetalMovement { get; init; }
    public string? DeliveryMode { get; init; }
    public string? BirthOutcome { get; init; }
    public int? BabyWeightGrams { get; init; }
    public int? ApgarScore1Min { get; init; }
    public int? ApgarScore5Min { get; init; }

    // Medications & Lab Tests
    public string? Medications { get; init; }
    public string? LabTests { get; init; }
    public string? Immunizations { get; init; }

    // Plan & Follow-up
    public string? CareInstructions { get; init; }
    public bool FollowUpRequired { get; init; }
    public DateTime? FollowUpDate { get; init; }
    public string? ReferralTo { get; init; }
    public string? Notes { get; init; }

    // Legacy field (for backward compatibility)
    public string? Description { get; init; }
}

// ── Reminder ──

public record ReminderDto
{
    public Guid Id { get; init; }
    public Guid ClientId { get; init; }
    public Guid? ProviderId { get; init; }
    public string ReminderType { get; init; } = "Appointment";
    public string Title { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public DateTime ScheduledDate { get; init; }
    public int NotifyBeforeMinutes { get; init; }
    public bool IsRecurring { get; init; }
    public string? RecurrencePattern { get; init; }
    public string Status { get; init; } = "Pending";
    public DateTime? SentAt { get; init; }
    public DateTime? CompletedAt { get; init; }
    public string? FacilityName { get; init; }
    public DateTime CreatedAt { get; init; }
}

public record CreateReminderDto
{
    public Guid ClientId { get; init; }
    public string ReminderType { get; init; } = "Appointment";
    public string Title { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public DateTime ScheduledDate { get; init; }
    public int NotifyBeforeMinutes { get; init; } = 1440;
    public bool IsRecurring { get; init; }
    public string? RecurrencePattern { get; init; }
    public string? FacilityName { get; init; }
}

// ── OTP ──

public record SendOtpRequestDto
{
    public string Email { get; init; } = string.Empty;
}

public record VerifyOtpRequestDto
{
    public string Email { get; init; } = string.Empty;
    public string Code { get; init; } = string.Empty;
}

public record ForgotPasswordRequestDto
{
    public string Email { get; init; } = string.Empty;
}

public record ResetPasswordRequestDto
{
    public string Email { get; init; } = string.Empty;
    public string Code { get; init; } = string.Empty;
    public string NewPassword { get; init; } = string.Empty;
}

// ── ActivityLog ──

public record ActivityLogDto
{
    public Guid Id { get; init; }
    public Guid UserId { get; init; }
    public string UserName { get; init; } = string.Empty;
    public string Action { get; init; } = string.Empty;
    public DateTime Timestamp { get; init; }
}

// ── Admin Dashboard ──

public record AdminStatsDto
{
    public int TotalUsers { get; init; }
    public int ActiveUsers { get; init; }
    public int TotalFacilities { get; init; }
    public int TotalProviders { get; init; }
    public int TotalClients { get; init; }
    public int TotalRecords { get; init; }
    public int TotalActivityLogs { get; init; }
    public Dictionary<string, int> UsersByRole { get; init; } = new();
}

// ── PIN Security ──

public record SetPinDto
{
    public string Pin { get; init; } = string.Empty;
    public string? CurrentPassword { get; init; } // Required when setting PIN for first time
}

public record ChangePinDto
{
    public string CurrentPin { get; init; } = string.Empty;
    public string NewPin { get; init; } = string.Empty;
}

public record VerifyPinDto
{
    public string Pin { get; init; } = string.Empty;
}

public record VerifyPinForPatientDto
{
    public string PatientCode { get; init; } = string.Empty; // QR code value
    public string Pin { get; init; } = string.Empty;
}

public record PinStatusDto
{
    public bool HasPinSet { get; init; }
    public bool IsLocked { get; init; }
    public int? LockoutMinutesRemaining { get; init; }
}
