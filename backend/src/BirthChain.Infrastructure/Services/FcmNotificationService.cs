using BirthChain.Infrastructure.Data;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
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
    private readonly IConfiguration _configuration;
    private readonly ILogger<FcmNotificationService> _logger;
    private readonly BirthChainDbContext _context;
    private static bool _isInitialized = false;
    private static bool _initializationAttempted = false;
    private static readonly object _lock = new object();

    public FcmNotificationService(
        IConfiguration configuration,
        ILogger<FcmNotificationService> logger,
        BirthChainDbContext context)
    {
        _configuration = configuration;
        _logger = logger;
        _context = context;

        // Initialize Firebase lazily - don't crash if it fails
        try
        {
            InitializeFirebase();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Firebase initialization failed in constructor - notifications disabled");
        }
    }

    private void InitializeFirebase()
    {
        lock (_lock)
        {
            if (_isInitialized || _initializationAttempted) return;
            _initializationAttempted = true;

            try
            {
                // Check if Firebase is already initialized
                if (FirebaseApp.DefaultInstance != null)
                {
                    _isInitialized = true;
                    return;
                }

                // Try to get credentials from environment variable (for Railway)
                var firebaseCredentialsJson = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON");

                if (!string.IsNullOrEmpty(firebaseCredentialsJson))
                {
                    _logger.LogInformation("Found FIREBASE_CREDENTIALS_JSON env var, length: {Length}", firebaseCredentialsJson.Length);

                    // Use credentials from environment variable (Railway deployment)
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromJson(firebaseCredentialsJson)
                    });
                    _logger.LogInformation("Firebase initialized from environment variable");
                    _isInitialized = true;
                }
                else
                {
                    // Try to use credentials file path from configuration
                    var credentialsPath = _configuration["Firebase:CredentialsPath"];
                    if (!string.IsNullOrEmpty(credentialsPath) && File.Exists(credentialsPath))
                    {
                        FirebaseApp.Create(new AppOptions
                        {
                            Credential = GoogleCredential.FromFile(credentialsPath)
                        });
                        _logger.LogInformation("Firebase initialized from file: {Path}", credentialsPath);
                        _isInitialized = true;
                    }
                    else
                    {
                        _logger.LogWarning("Firebase credentials not configured. Push notifications will not work.");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize Firebase: {Message}", ex.Message);
                // Don't rethrow - just disable notifications
            }
        }
    }

    public async Task SendNotificationAsync(string deviceToken, string title, string body, Dictionary<string, string>? data = null)
    {
        if (!_isInitialized)
        {
            _logger.LogWarning("Firebase not initialized. Cannot send notification.");
            return;
        }

        var message = new Message
        {
            Token = deviceToken,
            Notification = new FirebaseAdmin.Messaging.Notification
            {
                Title = title,
                Body = body
            },
            Data = data
        };

        try
        {
            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            _logger.LogInformation("FCM notification sent successfully. Message ID: {MessageId}", response);
        }
        catch (FirebaseMessagingException ex)
        {
            _logger.LogError(ex, "FCM notification failed: {Error}", ex.Message);
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
