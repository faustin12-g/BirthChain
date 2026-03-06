using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IAuthService
{
    Task<LoginResponseDto?> LoginAsync(LoginRequestDto request);
    Task<LoginResponseDto> RegisterPatientAsync(RegisterPatientDto request);
    Task SendVerificationOtpAsync(string email);
    Task<bool> VerifyEmailAsync(string email, string code);
    Task SendPasswordResetOtpAsync(string email);
    Task<bool> ResetPasswordAsync(string email, string code, string newPassword);
}
