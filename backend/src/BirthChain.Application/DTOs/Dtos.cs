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
    public string FacilityName { get; init; } = string.Empty;
    public string Specialty { get; init; } = string.Empty;
}

// ── Client ──

public record ClientDto
{
    public Guid Id { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
    public string QrCodeId { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
}

public record CreateClientDto
{
    public string FullName { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
}

// ── Record ──

public record RecordDto
{
    public Guid Id { get; init; }
    public Guid ClientId { get; init; }
    public Guid ProviderId { get; init; }
    public string Description { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }

    // Joined display names
    public string ClientName { get; init; } = string.Empty;
    public string ProviderName { get; init; } = string.Empty;
}

public record CreateRecordDto
{
    public Guid ClientId { get; init; }
    public string Description { get; init; } = string.Empty;
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
