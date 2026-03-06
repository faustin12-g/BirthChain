using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;

namespace BirthChain.Infrastructure.Services;

public sealed class ProfileService : IProfileService
{
    private readonly IUserRepository _userRepo;
    private readonly IFacilityRepository _facilityRepo;
    private readonly IProviderRepository _providerRepo;

    // PIN security configuration
    private const int MaxPinAttempts = 5;
    private const int LockoutMinutes = 15;

    public ProfileService(
        IUserRepository userRepo,
        IFacilityRepository facilityRepo,
        IProviderRepository providerRepo)
    {
        _userRepo = userRepo;
        _facilityRepo = facilityRepo;
        _providerRepo = providerRepo;
    }

    public async Task<UserDetailDto?> GetProfileAsync(Guid userId)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        if (user is null) return null;

        string? facilityName = null;
        if (user.FacilityId.HasValue)
        {
            var facility = await _facilityRepo.GetByIdAsync(user.FacilityId.Value);
            facilityName = facility?.Name;
        }

        return new UserDetailDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role,
            Phone = user.Phone,
            ProfileImageUrl = user.ProfileImageUrl,
            IsActive = user.IsActive,
            IsEmailVerified = user.IsEmailVerified,
            CreatedAt = user.CreatedAt,
            FacilityId = user.FacilityId,
            FacilityName = facilityName
        };
    }

    public async Task<UserDetailDto> UpdateProfileAsync(Guid userId, UpdateProfileDto dto)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        if (!string.IsNullOrWhiteSpace(dto.FullName)) user.FullName = dto.FullName;
        if (dto.Phone is not null) user.Phone = dto.Phone;

        await _userRepo.UpdateAsync(user);

        return (await GetProfileAsync(userId))!;
    }

    public async Task<UserDetailDto> UpdateProfileImageAsync(Guid userId, ProfileImageDto dto)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        // Validate base64 image
        if (string.IsNullOrWhiteSpace(dto.Base64Image))
        {
            throw new InvalidOperationException("Image data is required.");
        }

        // Validate content type
        var allowedTypes = new[] { "image/png", "image/jpeg", "image/jpg", "image/gif", "image/webp" };
        if (!allowedTypes.Contains(dto.ContentType.ToLowerInvariant()))
        {
            throw new InvalidOperationException("Invalid image type. Allowed: PNG, JPEG, GIF, WebP.");
        }

        // Create data URL
        user.ProfileImageUrl = $"data:{dto.ContentType};base64,{dto.Base64Image}";

        await _userRepo.UpdateAsync(user);

        return (await GetProfileAsync(userId))!;
    }

    public async Task RemoveProfileImageAsync(Guid userId)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        user.ProfileImageUrl = null;
        await _userRepo.UpdateAsync(user);
    }

    public async Task ChangePasswordAsync(Guid userId, ChangePasswordDto dto)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        // Verify current password
        if (!VerifyPassword(dto.CurrentPassword, user.PasswordHash))
        {
            throw new InvalidOperationException("Current password is incorrect.");
        }

        // Validate new password
        if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < 6)
        {
            throw new InvalidOperationException("New password must be at least 6 characters.");
        }

        // Update password
        user.PasswordHash = AuthService.HashPassword(dto.NewPassword);
        await _userRepo.UpdateAsync(user);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PIN Security Methods
    // ═══════════════════════════════════════════════════════════════════════

    public async Task<PinStatusDto> GetPinStatusAsync(Guid userId)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        var isLocked = user.PinLockoutEnd.HasValue && user.PinLockoutEnd > DateTime.UtcNow;
        int? lockoutMinutesRemaining = null;

        if (isLocked)
        {
            lockoutMinutesRemaining = (int)Math.Ceiling((user.PinLockoutEnd!.Value - DateTime.UtcNow).TotalMinutes);
        }

        return new PinStatusDto
        {
            HasPinSet = !string.IsNullOrEmpty(user.PinHash),
            IsLocked = isLocked,
            LockoutMinutesRemaining = lockoutMinutesRemaining
        };
    }

    public async Task SetPinAsync(Guid userId, SetPinDto dto)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        // If user already has a PIN, they should use ChangePinAsync
        if (!string.IsNullOrEmpty(user.PinHash))
        {
            throw new InvalidOperationException("PIN already set. Use change PIN instead.");
        }

        // Validate password (required when setting PIN for first time)
        if (string.IsNullOrWhiteSpace(dto.CurrentPassword))
        {
            throw new InvalidOperationException("Password is required to set PIN.");
        }

        if (!VerifyPassword(dto.CurrentPassword, user.PasswordHash))
        {
            throw new InvalidOperationException("Password is incorrect.");
        }

        // Validate PIN format (4-6 digits)
        if (!IsValidPin(dto.Pin))
        {
            throw new InvalidOperationException("PIN must be 4-6 digits.");
        }

        // Set the PIN
        user.PinHash = HashPin(dto.Pin);
        user.PinFailedAttempts = 0;
        user.PinLockoutEnd = null;

        await _userRepo.UpdateAsync(user);
    }

    public async Task ChangePinAsync(Guid userId, ChangePinDto dto)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        // Check if locked
        if (user.PinLockoutEnd.HasValue && user.PinLockoutEnd > DateTime.UtcNow)
        {
            var remaining = (int)Math.Ceiling((user.PinLockoutEnd.Value - DateTime.UtcNow).TotalMinutes);
            throw new InvalidOperationException($"PIN is locked. Try again in {remaining} minutes.");
        }

        // Must have existing PIN
        if (string.IsNullOrEmpty(user.PinHash))
        {
            throw new InvalidOperationException("No PIN set. Use set PIN instead.");
        }

        // Verify current PIN
        if (!VerifyPinHash(dto.CurrentPin, user.PinHash))
        {
            await IncrementFailedPinAttempts(user);
            throw new InvalidOperationException("Current PIN is incorrect.");
        }

        // Validate new PIN format
        if (!IsValidPin(dto.NewPin))
        {
            throw new InvalidOperationException("New PIN must be 4-6 digits.");
        }

        // Update PIN
        user.PinHash = HashPin(dto.NewPin);
        user.PinFailedAttempts = 0;
        user.PinLockoutEnd = null;

        await _userRepo.UpdateAsync(user);
    }

    public async Task RemovePinAsync(Guid userId, string currentPin)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        // Check if locked
        if (user.PinLockoutEnd.HasValue && user.PinLockoutEnd > DateTime.UtcNow)
        {
            var remaining = (int)Math.Ceiling((user.PinLockoutEnd.Value - DateTime.UtcNow).TotalMinutes);
            throw new InvalidOperationException($"PIN is locked. Try again in {remaining} minutes.");
        }

        // Must have existing PIN
        if (string.IsNullOrEmpty(user.PinHash))
        {
            throw new InvalidOperationException("No PIN set.");
        }

        // Verify current PIN
        if (!VerifyPinHash(currentPin, user.PinHash))
        {
            await IncrementFailedPinAttempts(user);
            throw new InvalidOperationException("PIN is incorrect.");
        }

        // Remove PIN
        user.PinHash = null;
        user.PinFailedAttempts = 0;
        user.PinLockoutEnd = null;

        await _userRepo.UpdateAsync(user);
    }

    public async Task<bool> VerifyPinAsync(Guid userId, string pin)
    {
        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException("User not found.");

        // Check if locked
        if (user.PinLockoutEnd.HasValue && user.PinLockoutEnd > DateTime.UtcNow)
        {
            var remaining = (int)Math.Ceiling((user.PinLockoutEnd.Value - DateTime.UtcNow).TotalMinutes);
            throw new InvalidOperationException($"PIN is locked. Try again in {remaining} minutes.");
        }

        // Must have PIN set
        if (string.IsNullOrEmpty(user.PinHash))
        {
            // No PIN set means access is granted (for backward compatibility)
            return true;
        }

        // Verify PIN
        if (!VerifyPinHash(pin, user.PinHash))
        {
            await IncrementFailedPinAttempts(user);
            var attemptsLeft = MaxPinAttempts - user.PinFailedAttempts;
            if (attemptsLeft > 0)
            {
                throw new InvalidOperationException($"Incorrect PIN. {attemptsLeft} attempts remaining.");
            }
            else
            {
                throw new InvalidOperationException($"PIN is now locked for {LockoutMinutes} minutes.");
            }
        }

        // PIN correct - reset failed attempts
        if (user.PinFailedAttempts > 0)
        {
            user.PinFailedAttempts = 0;
            user.PinLockoutEnd = null;
            await _userRepo.UpdateAsync(user);
        }

        return true;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Private Helper Methods
    // ═══════════════════════════════════════════════════════════════════════

    private static bool VerifyPassword(string password, string hash)
    {
        return AuthService.HashPassword(password) == hash;
    }

    private static bool IsValidPin(string pin)
    {
        if (string.IsNullOrWhiteSpace(pin)) return false;
        if (pin.Length < 4 || pin.Length > 6) return false;
        return pin.All(char.IsDigit);
    }

    private static string HashPin(string pin)
    {
        // Use same hashing as passwords for consistency
        return AuthService.HashPassword(pin);
    }

    private static bool VerifyPinHash(string pin, string hash)
    {
        return HashPin(pin) == hash;
    }

    private async Task IncrementFailedPinAttempts(Core.Entities.User user)
    {
        user.PinFailedAttempts++;

        if (user.PinFailedAttempts >= MaxPinAttempts)
        {
            user.PinLockoutEnd = DateTime.UtcNow.AddMinutes(LockoutMinutes);
        }

        await _userRepo.UpdateAsync(user);
    }
}
