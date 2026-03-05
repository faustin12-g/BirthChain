using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IAuthService
{
    Task<LoginResponseDto?> LoginAsync(LoginRequestDto request);
}
