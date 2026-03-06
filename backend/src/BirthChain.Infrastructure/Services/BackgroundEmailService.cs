using System.Collections.Concurrent;
using BirthChain.Application.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BirthChain.Infrastructure.Services;

public record EmailTask(string ToEmail, string Subject, string HtmlBody);

public interface IEmailQueue
{
    void QueueEmail(Func<IEmailService, Task> emailAction);
}

public sealed class BackgroundEmailService : BackgroundService, IEmailQueue
{
    private readonly ConcurrentQueue<Func<IEmailService, Task>> _queue = new();
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<BackgroundEmailService> _logger;
    private readonly SemaphoreSlim _signal = new(0);

    public BackgroundEmailService(IServiceScopeFactory scopeFactory, ILogger<BackgroundEmailService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    public void QueueEmail(Func<IEmailService, Task> emailAction)
    {
        _queue.Enqueue(emailAction);
        _signal.Release();
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Background email service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            await _signal.WaitAsync(stoppingToken);

            while (_queue.TryDequeue(out var emailAction))
            {
                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
                    await emailAction(emailService);
                    _logger.LogInformation("Background email sent successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send background email");
                }
            }
        }
    }
}
