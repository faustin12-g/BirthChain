namespace BirthChain.Application.Configuration;

/// <summary>
/// Strongly-typed JWT configuration bound from appsettings "Jwt" section.
/// </summary>
public sealed class JwtSettings
{
    public const string SectionName = "Jwt";

    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public int ExpireMinutes { get; set; } = 60;
}
