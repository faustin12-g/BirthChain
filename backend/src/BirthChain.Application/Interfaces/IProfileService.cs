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
}
