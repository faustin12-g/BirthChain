using BirthChain.Core.Entities;

namespace BirthChain.Application.Interfaces;

public interface IOtpRepository
{
    Task<OtpCode> AddAsync(OtpCode otp);
    Task<OtpCode?> GetValidAsync(string email, string code, string purpose);
    Task MarkUsedAsync(Guid id);
    Task InvalidateAllAsync(string email, string purpose);
}
