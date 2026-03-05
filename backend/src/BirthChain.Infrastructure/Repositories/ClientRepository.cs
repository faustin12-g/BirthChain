using BirthChain.Application.Interfaces;
using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Repositories;

public sealed class ClientRepository : IClientRepository
{
    private readonly BirthChainDbContext _db;

    public ClientRepository(BirthChainDbContext db) => _db = db;

    public async Task<Client> AddAsync(Client client)
    {
        _db.Clients.Add(client);
        await _db.SaveChangesAsync();
        return client;
    }

    public async Task<Client?> GetByIdAsync(Guid id)
        => await _db.Clients.FindAsync(id);

    public async Task<Client?> GetByQrCodeAsync(string qrCodeId)
        => await _db.Clients.FirstOrDefaultAsync(c => c.QrCodeId == qrCodeId);

    public async Task<IReadOnlyList<Client>> GetAllAsync()
        => await _db.Clients.OrderBy(c => c.FullName).ToListAsync();

    public async Task<IReadOnlyList<Client>> SearchAsync(string query)
    {
        var q = query.Trim().ToLower();
        return await _db.Clients
            .Where(c => c.FullName.ToLower().Contains(q)
                     || c.Phone.Contains(q)
                     || c.QrCodeId.ToLower().Contains(q)
                     || c.Email.ToLower().Contains(q))
            .OrderBy(c => c.FullName)
            .ToListAsync();
    }
}
