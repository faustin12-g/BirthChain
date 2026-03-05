using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IAuthService
{
    Task<LoginResponseDto?> LoginAsync(LoginRequestDto request);
    Task<LoginResponseDto> RegisterPatientAsync(RegisterPatientDto request);
}
