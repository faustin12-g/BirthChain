using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;

namespace BirthChain.Infrastructure.Services;

public sealed class ProfileService : IProfileService
{
    private readonly IUserRepository _userRepo;
    private readonly IFacilityRepository _facilityRepo;
    private readonly IProviderRepository _providerRepo;

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

    private static bool VerifyPassword(string password, string hash)
    {
        return AuthService.HashPassword(password) == hash;
    }
}
