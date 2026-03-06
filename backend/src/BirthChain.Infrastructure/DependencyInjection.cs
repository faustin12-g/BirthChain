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
        services.AddScoped<IFacilityRepository, FacilityRepository>();
        services.AddScoped<IOtpRepository, OtpRepository>();

        // Background email queue (singleton hosted service)
        services.AddSingleton<BackgroundEmailService>();
        services.AddSingleton<IEmailQueue>(sp => sp.GetRequiredService<BackgroundEmailService>());
        services.AddHostedService(sp => sp.GetRequiredService<BackgroundEmailService>());

        // Services
        services.AddScoped<IAuthService, AuthService>();
        services.AddHttpClient<IEmailService, EmailService>();  // Use HttpClient for Resend API
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IProviderService, ProviderService>();
        services.AddScoped<IClientService, ClientService>();
        services.AddScoped<IRecordService, RecordService>();
        services.AddScoped<IActivityLogService, ActivityLogService>();
        services.AddScoped<IFacilityService, FacilityService>();
        services.AddScoped<IAdminService, AdminService>();
        services.AddScoped<IProfileService, ProfileService>();
        services.AddScoped<IFcmNotificationService, FcmNotificationService>(); // FCM push notifications

        return services;
    }
}
