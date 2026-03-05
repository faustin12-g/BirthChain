namespace BirthChain.Core.Entities;

/// <summary>
/// Provider profile linked to a User.
/// Contains professional/facility details.
/// </summary>
public class Provider : BaseEntity
{
    public Guid UserId { get; set; }
    public string LicenseNumber { get; set; } = string.Empty;
    public string FacilityName { get; set; } = string.Empty;
    public string Specialty { get; set; } = string.Empty;
}
