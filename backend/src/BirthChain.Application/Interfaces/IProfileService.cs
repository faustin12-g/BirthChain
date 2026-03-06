using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IProfileService
{
    /// <summary>Get current user's profile</summary>
    Task<UserDetailDto?> GetProfileAsync(Guid userId);

    /// <summary>Update profile information (name, phone)</summary>
    Task<UserDetailDto> UpdateProfileAsync(Guid userId, UpdateProfileDto dto);

    /// <summary>Update profile image (base64)</summary>
    Task<UserDetailDto> UpdateProfileImageAsync(Guid userId, ProfileImageDto dto);

    /// <summary>Remove profile image</summary>
    Task RemoveProfileImageAsync(Guid userId);

    /// <summary>Change password</summary>
    Task ChangePasswordAsync(Guid userId, ChangePasswordDto dto);

    // PIN Security Methods

    /// <summary>Get PIN status (has PIN, is locked)</summary>
    Task<PinStatusDto> GetPinStatusAsync(Guid userId);

    /// <summary>Set PIN for the first time (requires password verification)</summary>
    Task SetPinAsync(Guid userId, SetPinDto dto);

    /// <summary>Change existing PIN</summary>
    Task ChangePinAsync(Guid userId, ChangePinDto dto);

    /// <summary>Remove PIN</summary>
    Task RemovePinAsync(Guid userId, string currentPin);

    /// <summary>Verify PIN for self (patient viewing own data)</summary>
    Task<bool> VerifyPinAsync(Guid userId, string pin);
}
