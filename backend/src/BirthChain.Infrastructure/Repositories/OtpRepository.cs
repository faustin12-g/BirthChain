using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class OtpRepository : IOtpRepository
{
    private readonly BirthChainDbContext _db;

    public OtpRepository(BirthChainDbContext db) => _db = db;

    public async Task<OtpCode> AddAsync(OtpCode otp)
    {
        _db.Set<OtpCode>().Add(otp);
        await _db.SaveChangesAsync();
        return otp;
    }

    public async Task<OtpCode?> GetValidAsync(string email, string code, string purpose)
    {
        return await _db.Set<OtpCode>()
            .Where(o => o.Email == email
                     && o.Code == code
                     && o.Purpose == purpose
                     && !o.IsUsed
                     && o.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();
    }

    public async Task MarkUsedAsync(Guid id)
    {
        var otp = await _db.Set<OtpCode>().FindAsync(id);
        if (otp is not null)
        {
            otp.IsUsed = true;
            await _db.SaveChangesAsync();
        }
    }

    public async Task InvalidateAllAsync(string email, string purpose)
    {
        var otps = await _db.Set<OtpCode>()
            .Where(o => o.Email == email && o.Purpose == purpose && !o.IsUsed)
            .ToListAsync();

        foreach (var otp in otps) otp.IsUsed = true;
        await _db.SaveChangesAsync();
    }
}
