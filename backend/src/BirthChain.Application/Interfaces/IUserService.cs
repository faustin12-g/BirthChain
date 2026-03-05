using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IUserService
{
    Task<UserDto> CreateAsync(CreateUserDto dto);
    Task<IReadOnlyList<UserDto>> GetAllAsync();
}
