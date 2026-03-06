using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using BirthChain.Application.Configuration;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace BirthChain.Infrastructure.Services;

public sealed class AuthService : IAuthService
{
    private readonly JwtSettings _jwt;
    private readonly IUserRepository _userRepo;
    private readonly IClientRepository _clientRepo;
    private readonly IFacilityRepository _facilityRepo;
    private readonly IOtpRepository _otpRepo;
    private readonly IEmailQueue _emailQueue;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IOptions<JwtSettings> jwtOptions,
        IUserRepository userRepo,
        IClientRepository clientRepo,
        IFacilityRepository facilityRepo,
        IOtpRepository otpRepo,
        IEmailQueue emailQueue,
        ILogger<AuthService> logger)
    {
        _jwt = jwtOptions.Value;
        _userRepo = userRepo;
        _clientRepo = clientRepo;
        _facilityRepo = facilityRepo;
        _otpRepo = otpRepo;
        _emailQueue = emailQueue;
        _logger = logger;
    }

    public async Task<LoginResponseDto?> LoginAsync(LoginRequestDto request)
    {
        var user = await _userRepo.GetByEmailAsync(request.Email);
        if (user is null || !user.IsActive) return null;

        // Check if user's facility is active (for facility-based users)
        if (user.FacilityId.HasValue)
        {
            var facility = await _facilityRepo.GetByIdAsync(user.FacilityId.Value);
            if (facility is not null && !facility.IsActive)
                return null; // Facility is deactivated
        }

        if (!VerifyPassword(request.Password, user.PasswordHash))
            return null;

        var expiresAt = DateTime.UtcNow.AddMinutes(_jwt.ExpireMinutes);

        var claims = new[]
        {
            new Claim("sub", user.Id.ToString()),
            new Claim("email", user.Email),
            new Claim("unique_name", user.FullName),
            new Claim("role", user.Role),
            new Claim("jti", Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.Key));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _jwt.Issuer,
            audience: _jwt.Audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: creds);

        // Resolve facility info if user is linked to one
        Guid? facilityId = user.FacilityId;
        string facilityName = "";
        if (facilityId.HasValue)
        {
            var facility = await _facilityRepo.GetByIdAsync(facilityId.Value);
            facilityName = facility?.Name ?? "";
        }

        return new LoginResponseDto
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            UserId = user.Id,
            Email = user.Email,
            FullName = user.FullName,
            Role = user.Role,
            ExpiresAt = expiresAt,
            FacilityId = facilityId,
            FacilityName = facilityName
        };
    }

    /// <summary>
    /// Self-registration for patients. Creates a User (role=Patient) + Client record,
    /// and returns a JWT so the patient is logged in immediately.
    /// If a Client with the same email already exists (registered by a provider),
    /// the existing Client is linked to the new User account.
    /// </summary>
    public async Task<LoginResponseDto> RegisterPatientAsync(RegisterPatientDto request)
    {
        // Check for duplicate email in Users table
        var existingUser = await _userRepo.GetByEmailAsync(request.Email);
        if (existingUser is not null)
            throw new InvalidOperationException($"An account with email '{request.Email}' already exists.");

        // 1. Create the User with Patient role
        var user = new User
        {
            FullName = request.FullName,
            Email = request.Email,
            PasswordHash = HashPassword(request.Password),
            Role = "Patient",
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        await _userRepo.AddAsync(user);

        // 2. Check if a Client already exists with this email (provider-registered)
        var existingClient = await _clientRepo.GetByEmailAsync(request.Email);
        if (existingClient is not null)
        {
            // Link existing client record to this new user account
            existingClient.UserId = user.Id;
            // Update any missing fields
            if (string.IsNullOrWhiteSpace(existingClient.Phone)) existingClient.Phone = request.Phone;
            if (string.IsNullOrWhiteSpace(existingClient.Gender)) existingClient.Gender = request.Gender;
            if (string.IsNullOrWhiteSpace(existingClient.Address)) existingClient.Address = request.Address;
            await _clientRepo.UpdateAsync(existingClient);
        }
        else
        {
            // Create a new Client record linked to this user
            var client = new Client
            {
                FullName = request.FullName,
                Phone = request.Phone,
                Email = request.Email,
                Gender = request.Gender,
                Address = request.Address,
                DateOfBirth = DateTime.SpecifyKind(request.DateOfBirth, DateTimeKind.Utc),
                QrCodeId = $"BC-{Guid.NewGuid().ToString("N")[..8].ToUpper()}",
                CreatedAt = DateTime.UtcNow,
                UserId = user.Id
            };
            await _clientRepo.AddAsync(client);
        }

        // 3. Issue JWT so the patient is logged in immediately
        var expiresAt2 = DateTime.UtcNow.AddMinutes(_jwt.ExpireMinutes);

        var claims2 = new[]
        {
            new Claim("sub", user.Id.ToString()),
            new Claim("email", user.Email),
            new Claim("unique_name", user.FullName),
            new Claim("role", user.Role),
            new Claim("jti", Guid.NewGuid().ToString())
        };

        var key2 = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.Key));
        var creds2 = new SigningCredentials(key2, SecurityAlgorithms.HmacSha256);

        var token2 = new JwtSecurityToken(
            issuer: _jwt.Issuer,
            audience: _jwt.Audience,
            claims: claims2,
            expires: expiresAt2,
            signingCredentials: creds2);

        return new LoginResponseDto
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token2),
            UserId = user.Id,
            Email = user.Email,
            FullName = user.FullName,
            Role = user.Role,
            ExpiresAt = expiresAt2
        };
    }

    // ── OTP Methods ──

    public async Task SendVerificationOtpAsync(string email)
    {
        var user = await _userRepo.GetByEmailAsync(email);
        if (user is null) throw new InvalidOperationException("Account not found.");
        if (user.IsEmailVerified) throw new InvalidOperationException("Email is already verified.");

        await _otpRepo.InvalidateAllAsync(email, "EmailVerification");
        var code = GenerateOtp();
        await _otpRepo.AddAsync(new OtpCode
        {
            Email = email,
            Code = code,
            Purpose = "EmailVerification",
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            CreatedAt = DateTime.UtcNow
        });
        _emailQueue.QueueEmail(async svc => await svc.SendOtpAsync(email, code, "EmailVerification"));
    }

    public async Task<bool> VerifyEmailAsync(string email, string code)
    {
        var otp = await _otpRepo.GetValidAsync(email, code, "EmailVerification");
        if (otp is null) return false;

        await _otpRepo.MarkUsedAsync(otp.Id);
        var user = await _userRepo.GetByEmailAsync(email);
        if (user is not null)
        {
            user.IsEmailVerified = true;
            await _userRepo.UpdateAsync(user);

            // Send welcome email with QR code ID
            var client = await _clientRepo.GetByEmailAsync(email);
            if (client is not null)
            {
                var fullName = user.FullName;
                var qrCode = client.QrCodeId;
                _emailQueue.QueueEmail(async svc => await svc.SendWelcomeEmailAsync(email, fullName, qrCode));
            }
        }
        return true;
    }

    public async Task SendPasswordResetOtpAsync(string email)
    {
        var user = await _userRepo.GetByEmailAsync(email);
        if (user is null) throw new InvalidOperationException("Account not found.");

        await _otpRepo.InvalidateAllAsync(email, "PasswordReset");
        var code = GenerateOtp();
        await _otpRepo.AddAsync(new OtpCode
        {
            Email = email,
            Code = code,
            Purpose = "PasswordReset",
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            CreatedAt = DateTime.UtcNow
        });
        _emailQueue.QueueEmail(async svc => await svc.SendOtpAsync(email, code, "PasswordReset"));
    }

    public async Task<bool> ResetPasswordAsync(string email, string code, string newPassword)
    {
        var otp = await _otpRepo.GetValidAsync(email, code, "PasswordReset");
        if (otp is null) return false;

        await _otpRepo.MarkUsedAsync(otp.Id);
        var user = await _userRepo.GetByEmailAsync(email);
        if (user is null) return false;

        user.PasswordHash = HashPassword(newPassword);
        await _userRepo.UpdateAsync(user);

        // Send confirmation email (fire-and-forget)
        var name = user.FullName;
        _emailQueue.QueueEmail(async svc => await svc.SendPasswordResetConfirmationAsync(email, name));
        return true;
    }

    private static string GenerateOtp()
    {
        using var rng = RandomNumberGenerator.Create();
        var bytes = new byte[4];
        rng.GetBytes(bytes);
        var number = Math.Abs(BitConverter.ToInt32(bytes, 0)) % 1_000_000;
        return number.ToString("D6");
    }

    // ── Password hashing helpers ──

    public static string HashPassword(string password)
    {
        byte[] salt = RandomNumberGenerator.GetBytes(16);
        string hash = Convert.ToBase64String(KeyDerivation.Pbkdf2(
            password: password,
            salt: salt,
            prf: KeyDerivationPrf.HMACSHA256,
            iterationCount: 100_000,
            numBytesRequested: 32));

        return $"{Convert.ToBase64String(salt)}:{hash}";
    }

    public static bool VerifyPassword(string password, string storedHash)
    {
        var parts = storedHash.Split(':');
        if (parts.Length != 2) return false;

        byte[] salt = Convert.FromBase64String(parts[0]);
        string expectedHash = parts[1];

        string actualHash = Convert.ToBase64String(KeyDerivation.Pbkdf2(
            password: password,
            salt: salt,
            prf: KeyDerivationPrf.HMACSHA256,
            iterationCount: 100_000,
            numBytesRequested: 32));

        return expectedHash == actualHash;
    }
}
