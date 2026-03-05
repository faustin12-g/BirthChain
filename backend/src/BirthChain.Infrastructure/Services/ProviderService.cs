using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;

namespace BirthChain.Infrastructure.Services;

public sealed class ProviderService : IProviderService
{
    private readonly IProviderRepository _providerRepo;
    private readonly IUserRepository _userRepo;

    public ProviderService(IProviderRepository providerRepo, IUserRepository userRepo)
    {
        _providerRepo = providerRepo;
        _userRepo = userRepo;
    }

    /// <summary>
    /// Creates both a User (with role Provider) and the linked Provider profile.
    /// </summary>
    public async Task<ProviderDto> CreateAsync(CreateProviderDto dto)
    {
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
            CreatedAt = DateTime.UtcNow
        };
        await _userRepo.AddAsync(user);

        // Create Provider profile
        var provider = new Provider
        {
            UserId = user.Id,
            LicenseNumber = dto.LicenseNumber,
            FacilityName = dto.FacilityName,
            Specialty = dto.Specialty
        };
        await _providerRepo.AddAsync(provider);

        return new ProviderDto
        {
            Id = provider.Id,
            UserId = user.Id,
            LicenseNumber = provider.LicenseNumber,
            FacilityName = provider.FacilityName,
            Specialty = provider.Specialty,
            FullName = user.FullName,
            Email = user.Email
        };
    }

    public async Task<IReadOnlyList<ProviderDto>> GetAllAsync()
    {
        var providers = await _providerRepo.GetAllAsync();
        var result = new List<ProviderDto>();

        foreach (var p in providers)
        {
            var user = await _userRepo.GetByIdAsync(p.UserId);
            result.Add(new ProviderDto
            {
                Id = p.Id,
                UserId = p.UserId,
                LicenseNumber = p.LicenseNumber,
                FacilityName = p.FacilityName,
                Specialty = p.Specialty,
                FullName = user?.FullName ?? "",
                Email = user?.Email ?? ""
            });
        }

        return result.AsReadOnly();
    }

    public async Task<ProviderDto?> GetByUserIdAsync(Guid userId)
    {
        var provider = await _providerRepo.GetByUserIdAsync(userId);
        if (provider is null) return null;

        var user = await _userRepo.GetByIdAsync(provider.UserId);

        return new ProviderDto
        {
            Id = provider.Id,
            UserId = provider.UserId,
            LicenseNumber = provider.LicenseNumber,
            FacilityName = provider.FacilityName,
            Specialty = provider.Specialty,
            FullName = user?.FullName ?? "",
            Email = user?.Email ?? ""
        };
    }
}
