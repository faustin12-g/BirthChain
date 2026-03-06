namespace BirthChain.Core.Entities;

/// <summary>
/// Healthcare facility (hospital, clinic, etc.).
/// Admin creates facilities; FacilityAdmins and Providers are assigned to one.
/// </summary>
public class Facility : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
