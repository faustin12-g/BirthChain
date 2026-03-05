using BirthChain.Application.Interfaces;
using BirthChain.Infrastructure.Data;
using BirthChain.Infrastructure.Repositories;
using BirthChain.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BirthChain.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, string connectionString)
    {
        // EF Core + PostgreSQL
        services.AddDbContext<BirthChainDbContext>(options =>
            options.UseNpgsql(connectionString));

        // Repositories
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IProviderRepository, ProviderRepository>();
        services.AddScoped<IClientRepository, ClientRepository>();
        services.AddScoped<IRecordRepository, RecordRepository>();
        services.AddScoped<IActivityLogRepository, ActivityLogRepository>();

        // Services
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IProviderService, ProviderService>();
        services.AddScoped<IClientService, ClientService>();
        services.AddScoped<IRecordService, RecordService>();
        services.AddScoped<IActivityLogService, ActivityLogService>();

        return services;
    }
}
