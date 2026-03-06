namespace BirthChain.Application.Interfaces;

public interface IEmailService
{
    Task SendOtpAsync(string toEmail, string code, string purpose);
}
