namespace BirthChain.Application.DTOs;

// ══════════════════════════════════════════════════════════════════════════════
// FACILITY MANAGEMENT DTOs
// ══════════════════════════════════════════════════════════════════════════════

public record UpdateFacilityDto(
    string? Name,
    string? Address,
    string? Phone,
    string? Email
);

public record FacilityDetailDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
    public int ProviderCount { get; init; }
    public int UserCount { get; init; }
}

// ══════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT DTOs
// ══════════════════════════════════════════════════════════════════════════════

public record UserDetailDto
{
    public Guid Id { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public string? Phone { get; init; }
    public string? ProfileImageUrl { get; init; }
    public bool IsActive { get; init; }
    public bool IsEmailVerified { get; init; }
    public DateTime CreatedAt { get; init; }
    public Guid? FacilityId { get; init; }
    public string? FacilityName { get; init; }
}

public record UpdateUserDto(
    string? FullName,
    string? Phone,
    Guid? FacilityId
);

public record AdminUpdateUserDto(
    string? FullName,
    string? Phone,
    string? Role,
    Guid? FacilityId
);

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDER MANAGEMENT DTOs
// ══════════════════════════════════════════════════════════════════════════════

public record ProviderDetailDto
{
    public Guid Id { get; init; }
    public Guid UserId { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string? Phone { get; init; }
    public string? ProfileImageUrl { get; init; }
    public string LicenseNumber { get; init; } = string.Empty;
    public string Specialty { get; init; } = string.Empty;
    public Guid FacilityId { get; init; }
    public string FacilityName { get; init; } = string.Empty;
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public record UpdateProviderDto(
    string? FullName,
    string? Phone,
    string? LicenseNumber,
    string? Specialty
);

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE UPDATE DTOs
// ══════════════════════════════════════════════════════════════════════════════

public record UpdateProfileDto(
    string? FullName,
    string? Phone
);

public record ChangePasswordDto(
    string CurrentPassword,
    string NewPassword
);

public record ProfileImageDto(
    string Base64Image,
    string ContentType  // e.g., "image/png", "image/jpeg"
);

// ══════════════════════════════════════════════════════════════════════════════
// STATISTICS DTOs
// ══════════════════════════════════════════════════════════════════════════════

public record DashboardStatsDto
{
    public int TotalFacilities { get; init; }
    public int ActiveFacilities { get; init; }
    public int TotalUsers { get; init; }
    public int ActiveUsers { get; init; }
    public int TotalProviders { get; init; }
    public int TotalPatients { get; init; }
    public int TotalRecords { get; init; }
}

public record FacilityStatsDto
{
    public Guid FacilityId { get; init; }
    public string FacilityName { get; init; } = string.Empty;
    public int ProviderCount { get; init; }
    public int PatientCount { get; init; }
    public int RecordCount { get; init; }
}
