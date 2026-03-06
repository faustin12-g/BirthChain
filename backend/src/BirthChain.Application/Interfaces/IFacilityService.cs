using BirthChain.Application.DTOs;

namespace BirthChain.Application.Interfaces;

public interface IFacilityService
{
    Task<FacilityDto> CreateAsync(CreateFacilityDto dto);
    Task<IReadOnlyList<FacilityDto>> GetAllAsync();
    Task<FacilityDto?> GetByIdAsync(Guid id);
    Task<FacilityDto> CreateFacilityAdminAsync(CreateFacilityAdminDto dto);
}
