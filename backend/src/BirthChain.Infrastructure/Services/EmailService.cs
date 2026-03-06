using System.Net;
using System.Net.Http.Headers;
using System.Net.Mail;
using System.Reflection;
using System.Text;
using System.Text.Json;
using BirthChain.Application.Configuration;
using BirthChain.Application.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BirthChain.Infrastructure.Services;

public sealed class EmailService : IEmailService
{
    private readonly SmtpSettings _smtp;
    private readonly ILogger<EmailService> _logger;
    private readonly HttpClient _httpClient;

    private static readonly Lazy<string> _logoBase64 = new(() =>
    {
        try
        {
            var asm = Assembly.GetExecutingAssembly();
            using var stream = asm.GetManifestResourceStream("BirthChain.Infrastructure.Resources.logo.png");
            if (stream == null) return "";
            using var ms = new MemoryStream();
            stream.CopyTo(ms);
            return Convert.ToBase64String(ms.ToArray());
        }
        catch { return ""; }
    });

    public EmailService(IOptions<SmtpSettings> smtpOptions, ILogger<EmailService> logger, HttpClient? httpClient = null)
    {
        _smtp = smtpOptions.Value;
        _logger = logger;
        _httpClient = httpClient ?? new HttpClient();
    }

    // ── Shared helpers ──

    private static string LogoImg => string.IsNullOrEmpty(_logoBase64.Value)
        ? ""
        : $"<img src=\"data:image/png;base64,{_logoBase64.Value}\" alt=\"BirthChain\" style=\"height:56px;width:auto;display:inline-block;margin-bottom:8px;\" />";

    private static string LogoImgSmall => string.IsNullOrEmpty(_logoBase64.Value)
        ? ""
        : $"<img src=\"data:image/png;base64,{_logoBase64.Value}\" alt=\"\" style=\"height:20px;width:auto;vertical-align:middle;margin-right:6px;opacity:0.6;\" />";

    private static string Wrap(string innerHtml) => $"""
        <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:520px;margin:0 auto;padding:0;border:1px solid #e0e0e0;border-radius:12px;overflow:hidden;">
            <div style="background:#1A3C6D;padding:20px;text-align:center;">
                {LogoImg}
                <h1 style="color:#fff;margin:0;font-size:22px;">BirthChain</h1>
                <p style="color:#F58B1F;margin:4px 0 0;font-size:13px;">Secure Birth &amp; Health Record Management</p>
            </div>
            <div style="padding:24px 28px;">
                {innerHtml}
            </div>
            <div style="background:#f5f5f5;padding:14px 28px;text-align:center;font-size:11px;color:#999;">
                {LogoImgSmall}
                &copy; 2026 BirthChain &middot; This is an automated message, please do not reply.
            </div>
        </div>
        """;

    private static string QrBadge(string qrCodeId) => $"""
        <div style="text-align:center;margin:20px 0;">
            <div style="display:inline-block;background:#1A3C6D;color:#fff;padding:14px 28px;border-radius:10px;">
                <div style="font-size:11px;text-transform:uppercase;letter-spacing:2px;color:#F58B1F;margin-bottom:6px;">Your Unique ID</div>
                <div style="font-size:26px;font-weight:bold;letter-spacing:4px;">{qrCodeId}</div>
            </div>
        </div>
        <p style="text-align:center;color:#666;font-size:12px;">Show this ID or scan your QR code at any BirthChain facility for instant access to your records.</p>
        """;

    private async Task SendAsync(string toEmail, string subject, string htmlBody)
    {
        // Use Resend API if configured (required for Railway/cloud platforms)
        if (_smtp.UseResend && !string.IsNullOrEmpty(_smtp.ResendApiKey))
        {
            await SendViaResendAsync(toEmail, subject, htmlBody);
        }
        else
        {
            await SendViaSmtpAsync(toEmail, subject, htmlBody);
        }
    }

    private async Task SendViaResendAsync(string toEmail, string subject, string htmlBody)
    {
        var fromEmail = string.IsNullOrEmpty(_smtp.Email)
            ? "BirthChain <onboarding@resend.dev>"
            : $"{_smtp.DisplayName} <{_smtp.Email}>";

        // If no custom domain, use Resend's test domain
        if (!_smtp.Email.Contains("@") || _smtp.Email.EndsWith("@gmail.com"))
        {
            fromEmail = "BirthChain <onboarding@resend.dev>";
        }

        var payload = new
        {
            from = fromEmail,
            to = new[] { toEmail },
            subject = subject,
            html = htmlBody
        };

        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _smtp.ResendApiKey);

        try
        {
            var response = await _httpClient.PostAsync("https://api.resend.com/emails", content);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Email sent via Resend to {Email}: {Subject}", toEmail, subject);
            }
            else
            {
                _logger.LogError("Resend API error for {Email}: {StatusCode} - {Body}",
                    toEmail, response.StatusCode, responseBody);
                throw new Exception($"Resend API error: {response.StatusCode} - {responseBody}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email via Resend to {Email}: {Subject}", toEmail, subject);
            throw;
        }
    }

    private async Task SendViaSmtpAsync(string toEmail, string subject, string htmlBody)
    {
        using var client = new SmtpClient(_smtp.Host, _smtp.Port)
        {
            Credentials = new NetworkCredential(_smtp.Email, _smtp.Password),
            EnableSsl = true
        };

        var msg = new MailMessage
        {
            From = new MailAddress(_smtp.Email, _smtp.DisplayName),
            Subject = subject,
            IsBodyHtml = true,
            Body = htmlBody
        };
        msg.To.Add(toEmail);

        try
        {
            await client.SendMailAsync(msg);
            _logger.LogInformation("Email sent via SMTP to {Email}: {Subject}", toEmail, subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email via SMTP to {Email}: {Subject}. Host: {Host}, Port: {Port}",
                toEmail, subject, _smtp.Host, _smtp.Port);
            throw;
        }
    }

    // ── OTP ──

    public async Task SendOtpAsync(string toEmail, string code, string purpose)
    {
        var subject = purpose switch
        {
            "EmailVerification" => "BirthChain — Verify Your Email",
            "PasswordReset" => "BirthChain — Password Reset Code",
            _ => "BirthChain — Verification Code"
        };

        var inner = $"""
            <p style="margin-top:0;">Hello,</p>
            <p>{(purpose == "PasswordReset" ? "You requested a password reset." : "Please verify your email address to activate your BirthChain account.")}</p>
            <p>Your verification code is:</p>
            <div style="text-align:center;margin:24px 0;">
                <span style="background:#1A3C6D;color:#fff;font-size:32px;letter-spacing:10px;padding:14px 28px;border-radius:10px;font-weight:bold;">{code}</span>
            </div>
            <p style="color:#888;font-size:13px;">This code expires in <strong>10 minutes</strong>. If you didn't request this, you can safely ignore this email.</p>
            """;

        await SendAsync(toEmail, subject, Wrap(inner));
    }

    // ── Welcome (after verification) ──

    public async Task SendWelcomeEmailAsync(string toEmail, string fullName, string qrCodeId)
    {
        var inner = $"""
            <h2 style="color:#1A3C6D;margin-top:0;">Welcome to BirthChain, {fullName}!</h2>
            <p>Your email has been verified and your account is now fully active.</p>
            <p>Here is your <strong>unique patient ID</strong> — keep it safe! You can use it at any BirthChain-enabled facility to access your medical records instantly.</p>
            {QrBadge(qrCodeId)}
            <div style="background:#FFF8F0;border-left:4px solid #F58B1F;padding:12px 16px;margin:16px 0;border-radius:0 8px 8px 0;">
                <strong style="color:#F58B1F;">Tip:</strong> Save this email or take a screenshot of your ID. You'll need it when visiting healthcare facilities.
            </div>
            <p>You can now log in and view your health records anytime.</p>
            """;

        await SendAsync(toEmail, "Welcome to BirthChain — Your Patient ID", Wrap(inner));
    }

    // ── Record Added ──

    public async Task SendRecordAddedEmailAsync(string toEmail, string patientName, string qrCodeId,
        string providerName, string facility, string description, DateTime recordDate)
    {
        var descriptionHtml = FormatRecordDescription(description);

        var inner = $"""
            <h2 style="color:#1A3C6D;margin-top:0;">New Medical Record Added</h2>
            <p>Hello <strong>{patientName}</strong>,</p>
            <p>A new record has been added to your BirthChain health profile:</p>
            <table style="width:100%;border-collapse:collapse;margin:16px 0;">
                <tr style="border-bottom:1px solid #eee;">
                    <td style="padding:10px 0;color:#888;width:120px;">Provider</td>
                    <td style="padding:10px 0;font-weight:600;">{providerName}</td>
                </tr>
                <tr style="border-bottom:1px solid #eee;">
                    <td style="padding:10px 0;color:#888;">Facility</td>
                    <td style="padding:10px 0;font-weight:600;">{facility}</td>
                </tr>
                <tr style="border-bottom:1px solid #eee;">
                    <td style="padding:10px 0;color:#888;">Date</td>
                    <td style="padding:10px 0;font-weight:600;">{recordDate:MMMM d, yyyy}</td>
                </tr>
            </table>
            <div style="background:#f8f9fa;border-radius:8px;padding:16px;margin:16px 0;">
                <div style="font-size:12px;color:#888;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px;">Record Details</div>
                {descriptionHtml}
            </div>
            {QrBadge(qrCodeId)}
            <p style="color:#666;font-size:13px;">Log in to your BirthChain account to view your complete medical history.</p>
            """;

        await SendAsync(toEmail, $"BirthChain — New Record Added by {providerName}", Wrap(inner));
    }

    // ── Password Reset Confirmation ──

    public async Task SendPasswordResetConfirmationAsync(string toEmail, string fullName)
    {
        var inner = $"""
            <h2 style="color:#1A3C6D;margin-top:0;">Password Reset Successful</h2>
            <p>Hello <strong>{fullName}</strong>,</p>
            <p>Your BirthChain password has been successfully reset.</p>
            <div style="background:#FFF8F0;border-left:4px solid #F58B1F;padding:12px 16px;margin:16px 0;border-radius:0 8px 8px 0;">
                <strong style="color:#F58B1F;">Warning:</strong> If you did not reset your password, please contact support immediately as your account may be compromised.
            </div>
            <p>You can now log in with your new password.</p>
            """;

        await SendAsync(toEmail, "BirthChain — Password Reset Confirmation", Wrap(inner));
    }

    // ── Provider Welcome ──

    public async Task SendProviderWelcomeEmailAsync(string toEmail, string fullName, string facilityName, string specialty)
    {
        var inner = $"""
            <h2 style="color:#1A3C6D;margin-top:0;">Welcome to BirthChain, Dr. {fullName}!</h2>
            <p>You have been added as a healthcare provider on the BirthChain platform.</p>
            <table style="width:100%;border-collapse:collapse;margin:16px 0;">
                <tr style="border-bottom:1px solid #eee;">
                    <td style="padding:10px 0;color:#888;width:120px;">Facility</td>
                    <td style="padding:10px 0;font-weight:600;">{facilityName}</td>
                </tr>
                <tr style="border-bottom:1px solid #eee;">
                    <td style="padding:10px 0;color:#888;">Specialty</td>
                    <td style="padding:10px 0;font-weight:600;">{specialty}</td>
                </tr>
            </table>
            <p>You can now log in and start managing patient records.</p>
            <p style="color:#888;font-size:13px;">Your login credentials were sent separately by your administrator.</p>
            """;

        await SendAsync(toEmail, $"BirthChain — Welcome to {facilityName}", Wrap(inner));
    }

    // ── Description formatter ──

    private static string FormatRecordDescription(string description)
    {
        try
        {
            var doc = JsonSerializer.Deserialize<Dictionary<string, object>>(description);
            if (doc is not null)
            {
                var html = "";
                foreach (var kv in doc)
                {
                    var key = System.Globalization.CultureInfo.CurrentCulture.TextInfo
                        .ToTitleCase(kv.Key.Replace("_", " "));
                    html += $"<div style=\"margin-bottom:6px;\"><span style=\"color:#888;\">{key}:</span> <strong>{kv.Value}</strong></div>";
                }
                return html;
            }
        }
        catch { /* not JSON */ }

        return $"<p>{description}</p>";
    }
}
