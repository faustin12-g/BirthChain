using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;

namespace BirthChain.Infrastructure.Services;

public sealed class FacilityService : IFacilityService
{
    private readonly IFacilityRepository _facilityRepo;
    private readonly IUserRepository _userRepo;

    public FacilityService(IFacilityRepository facilityRepo, IUserRepository userRepo)
    {
        _facilityRepo = facilityRepo;
        _userRepo = userRepo;
    }

    public async Task<FacilityDto> CreateAsync(CreateFacilityDto dto)
    {
        // Check uniqueness
        var existing = await _facilityRepo.GetByNameAsync(dto.Name);
        if (existing is not null)
            throw new InvalidOperationException($"A facility named '{dto.Name}' already exists.");

        var facility = new Facility
        {
            Name = dto.Name,
            Address = dto.Address,
            Phone = dto.Phone,
            Email = dto.Email,
            CreatedAt = DateTime.UtcNow
        };

        await _facilityRepo.AddAsync(facility);
        return ToDto(facility);
    }

    public async Task<IReadOnlyList<FacilityDto>> GetAllAsync()
    {
        var facilities = await _facilityRepo.GetAllAsync();
        return facilities.Select(ToDto).ToList().AsReadOnly();
    }

    public async Task<FacilityDto?> GetByIdAsync(Guid id)
    {
        var facility = await _facilityRepo.GetByIdAsync(id);
        return facility is null ? null : ToDto(facility);
    }

    /// <summary>
    /// Admin creates a FacilityAdmin user assigned to a facility.
    /// </summary>
    public async Task<FacilityDto> CreateFacilityAdminAsync(CreateFacilityAdminDto dto)
    {
        // Validate facility exists
        var facility = await _facilityRepo.GetByIdAsync(dto.FacilityId)
            ?? throw new InvalidOperationException($"Facility '{dto.FacilityId}' not found.");

        // Check email uniqueness
        var existingUser = await _userRepo.GetByEmailAsync(dto.Email);
        if (existingUser is not null)
            throw new InvalidOperationException($"A user with email '{dto.Email}' already exists.");

        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            PasswordHash = AuthService.HashPassword(dto.Password),
            Role = "FacilityAdmin",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            FacilityId = dto.FacilityId
        };

        await _userRepo.AddAsync(user);
        return ToDto(facility);
    }

    private static FacilityDto ToDto(Facility f) => new()
    {
        Id = f.Id,
        Name = f.Name,
        Address = f.Address,
        Phone = f.Phone,
        Email = f.Email,
        CreatedAt = f.CreatedAt
    };
}
