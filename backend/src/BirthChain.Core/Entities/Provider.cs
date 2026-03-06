namespace BirthChain.Core.Entities;

/// <summary>
/// Provider profile linked to a User and a Facility.
/// Contains professional details.
/// </summary>
public class Provider : BaseEntity
{
    public Guid UserId { get; set; }
    public string LicenseNumber { get; set; } = string.Empty;

    /// <summary>
    /// Foreign key to the assigned facility.
    /// </summary>
    public Guid FacilityId { get; set; }

    public string Specialty { get; set; } = string.Empty;
}
