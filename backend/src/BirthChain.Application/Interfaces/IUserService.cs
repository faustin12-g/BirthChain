using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IUserService
{
    Task<UserDto> CreateAsync(CreateUserDto dto);
    Task<IReadOnlyList<UserDto>> GetAllAsync();
    Task<UserDto?> GetByIdAsync(Guid id);
    Task<bool> ToggleActiveAsync(Guid id);
    Task<bool> DeleteAsync(Guid id);
    Task<AdminStatsDto> GetStatsAsync();
}
