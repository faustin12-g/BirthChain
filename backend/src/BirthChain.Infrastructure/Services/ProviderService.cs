using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;

namespace BirthChain.Infrastructure.Services;

public sealed class ProviderService : IProviderService
{
    private readonly IProviderRepository _providerRepo;
    private readonly IUserRepository _userRepo;
    private readonly IFacilityRepository _facilityRepo;

    public ProviderService(IProviderRepository providerRepo, IUserRepository userRepo, IFacilityRepository facilityRepo)
    {
        _providerRepo = providerRepo;
        _userRepo = userRepo;
        _facilityRepo = facilityRepo;
    }

    /// <summary>
    /// Creates both a User (with role Provider) and the linked Provider profile.
    /// Can be called by Admin or FacilityAdmin.
    /// </summary>
    public async Task<ProviderDto> CreateAsync(CreateProviderDto dto)
    {
        // Validate facility exists
        var facility = await _facilityRepo.GetByIdAsync(dto.FacilityId)
            ?? throw new InvalidOperationException($"Facility not found.");

        // Check email uniqueness
        var existing = await _userRepo.GetByEmailAsync(dto.Email);
        if (existing is not null)
            throw new InvalidOperationException($"A user with email '{dto.Email}' already exists.");

        // Create User
        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            PasswordHash = AuthService.HashPassword(dto.Password),
            Role = "Provider",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            FacilityId = dto.FacilityId
        };
        await _userRepo.AddAsync(user);

        // Create Provider profile
        var provider = new Provider
        {
            UserId = user.Id,
            LicenseNumber = dto.LicenseNumber,
            FacilityId = dto.FacilityId,
            Specialty = dto.Specialty
        };
        await _providerRepo.AddAsync(provider);

        return new ProviderDto
        {
            Id = provider.Id,
            UserId = user.Id,
            LicenseNumber = provider.LicenseNumber,
            FacilityId = provider.FacilityId,
            FacilityName = facility.Name,
            Specialty = provider.Specialty,
            FullName = user.FullName,
            Email = user.Email
        };
    }

    public async Task<IReadOnlyList<ProviderDto>> GetAllAsync()
    {
        var providers = await _providerRepo.GetAllAsync();
        return await ToDtoListAsync(providers);
    }

    public async Task<ProviderDto?> GetByUserIdAsync(Guid userId)
    {
        var provider = await _providerRepo.GetByUserIdAsync(userId);
        if (provider is null) return null;

        var user = await _userRepo.GetByIdAsync(provider.UserId);
        var facility = await _facilityRepo.GetByIdAsync(provider.FacilityId);

        return new ProviderDto
        {
            Id = provider.Id,
            UserId = provider.UserId,
            LicenseNumber = provider.LicenseNumber,
            FacilityId = provider.FacilityId,
            FacilityName = facility?.Name ?? "",
            Specialty = provider.Specialty,
            FullName = user?.FullName ?? "",
            Email = user?.Email ?? ""
        };
    }

    public async Task<IReadOnlyList<ProviderDto>> GetByFacilityIdAsync(Guid facilityId)
    {
        var providers = await _providerRepo.GetByFacilityIdAsync(facilityId);
        return await ToDtoListAsync(providers);
    }

    private async Task<IReadOnlyList<ProviderDto>> ToDtoListAsync(IReadOnlyList<Provider> providers)
    {
        var result = new List<ProviderDto>();
        foreach (var p in providers)
        {
            var user = await _userRepo.GetByIdAsync(p.UserId);
            var facility = await _facilityRepo.GetByIdAsync(p.FacilityId);
            result.Add(new ProviderDto
            {
                Id = p.Id,
                UserId = p.UserId,
                LicenseNumber = p.LicenseNumber,
                FacilityId = p.FacilityId,
                FacilityName = facility?.Name ?? "",
                Specialty = p.Specialty,
                FullName = user?.FullName ?? "",
                Email = user?.Email ?? ""
            });
        }
        return result.AsReadOnly();
    }
}
