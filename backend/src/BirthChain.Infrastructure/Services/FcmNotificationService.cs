using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BirthChain.Infrastructure.Data;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BirthChain.Infrastructure.Services;

public interface IFcmNotificationService
{
    Task SendNotificationAsync(string deviceToken, string title, string body, Dictionary<string, string>? data = null);
    Task SendNotificationToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null);
}

public class FcmNotificationService : IFcmNotificationService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FcmNotificationService> _logger;
    private readonly BirthChainDbContext _context;

    public FcmNotificationService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<FcmNotificationService> logger,
        BirthChainDbContext context)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
        _context = context;
    }

    public async Task SendNotificationAsync(string deviceToken, string title, string body, Dictionary<string, string>? data = null)
    {
        var serverKey = _configuration["Firebase:ServerKey"];
        if (string.IsNullOrEmpty(serverKey))
        {
            _logger.LogWarning("Firebase ServerKey not configured. Notification not sent.");
            return;
        }

        var message = new
        {
            to = deviceToken,
            notification = new
            {
                title,
                body
            },
            data
        };

        var json = JsonSerializer.Serialize(message);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("key", "=" + serverKey);

        try
        {
            var response = await _httpClient.PostAsync("https://fcm.googleapis.com/fcm/send", content);
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogError("FCM notification failed: {Error}", error);
            }
            else
            {
                _logger.LogInformation("FCM notification sent successfully to {Token}", deviceToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending FCM notification");
        }
    }

    public async Task SendNotificationToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null || string.IsNullOrEmpty(user.FcmToken))
        {
            _logger.LogWarning("User {UserId} not found or has no FCM token", userId);
            return;
        }

        await SendNotificationAsync(user.FcmToken, title, body, data);
    }
}
