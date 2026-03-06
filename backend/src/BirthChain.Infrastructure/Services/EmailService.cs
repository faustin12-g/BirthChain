using System.Net;
using System.Net.Mail;
using BirthChain.Application.Configuration;
using BirthChain.Application.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BirthChain.Infrastructure.Services;

public sealed class EmailService : IEmailService
{
    private readonly SmtpSettings _smtp;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IOptions<SmtpSettings> smtpOptions, ILogger<EmailService> logger)
    {
        _smtp = smtpOptions.Value;
        _logger = logger;
    }

    public async Task SendOtpAsync(string toEmail, string code, string purpose)
    {
        var subject = purpose switch
        {
            "EmailVerification" => "BirthChain - Verify Your Email",
            "PasswordReset" => "BirthChain - Password Reset Code",
            _ => "BirthChain - Verification Code"
        };

        var body = $"""
            <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #e0e0e0;border-radius:12px;">
                <div style="text-align:center;margin-bottom:20px;">
                    <h2 style="color:#1A3C6D;margin:0;">BirthChain</h2>
                </div>
                <p>Hello,</p>
                <p>{(purpose == "PasswordReset" ? "You requested a password reset." : "Please verify your email address.")}</p>
                <p>Your verification code is:</p>
                <div style="text-align:center;margin:24px 0;">
                    <span style="background:#1A3C6D;color:#fff;font-size:28px;letter-spacing:8px;padding:12px 24px;border-radius:8px;font-weight:bold;">{code}</span>
                </div>
                <p style="color:#888;font-size:13px;">This code expires in 10 minutes. If you didn't request this, ignore this email.</p>
            </div>
            """;

        using var client = new SmtpClient(_smtp.Host, _smtp.Port)
        {
            Credentials = new NetworkCredential(_smtp.Email, _smtp.Password),
            EnableSsl = true
        };

        var msg = new MailMessage
        {
            From = new MailAddress(_smtp.Email, _smtp.DisplayName),
            Subject = subject,
            Body = body,
            IsBodyHtml = true
        };
        msg.To.Add(toEmail);

        try
        {
            await client.SendMailAsync(msg);
            _logger.LogInformation("OTP email sent to {Email} for {Purpose}", toEmail, purpose);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send OTP email to {Email}", toEmail);
            throw new InvalidOperationException("Failed to send verification email. Please try again.");
        }
    }
}
