using BirthChain.Core.Entities;
using BirthChain.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BirthChain.Infrastructure.Data;

public static class DbInitializer
{
    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<BirthChainDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<BirthChainDbContext>>();

        await db.Database.MigrateAsync();
        logger.LogInformation("Database migrated successfully.");

        // Seed admin user if not present
        if (!await db.Users.AnyAsync(u => u.Email == "nyaepeace@gmail.com"))
        {
            var admin = new User
            {
                Id = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
                Email = "nyaepeace@gmail.com",
                FullName = "System Admin",
                PasswordHash = AuthService.HashPassword("UhoRaho@842"),
                Role = "Admin",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            db.Users.Add(admin);
            await db.SaveChangesAsync();
            logger.LogInformation("Seeded admin user: nyaepeace@gmail.com");
        }
    }
}
