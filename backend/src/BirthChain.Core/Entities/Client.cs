namespace BirthChain.Core.Entities;

/// <summary>
/// Client / Patient — can be registered by a provider or self-registered.
/// </summary>
public class Client : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Gender { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public string QrCodeId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Nullable — set when a patient creates their own account.</summary>
    public Guid? UserId { get; set; }

    // ═══════════════════════════════════════════════════════════════════════
    // Patient Category & Medical Profile
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Patient category: General, Maternal, ChronicDisease, Pediatric, Emergency</summary>
    public string PatientCategory { get; set; } = "General";

    /// <summary>Blood type: A+, A-, B+, B-, AB+, AB-, O+, O-</summary>
    public string? BloodType { get; set; }

    /// <summary>Known allergies (comma-separated or JSON)</summary>
    public string? Allergies { get; set; }

    /// <summary>Chronic conditions (comma-separated or JSON): Diabetes, Hypertension, Asthma, etc.</summary>
    public string? ChronicConditions { get; set; }

    /// <summary>Emergency contact name</summary>
    public string? EmergencyContactName { get; set; }

    /// <summary>Emergency contact phone</summary>
    public string? EmergencyContactPhone { get; set; }

    // ═══════════════════════════════════════════════════════════════════════
    // Maternal Health Fields (for pregnant women)
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Is currently pregnant</summary>
    public bool IsPregnant { get; set; } = false;

    /// <summary>Last Menstrual Period date</summary>
    public DateTime? LastMenstrualPeriod { get; set; }

    /// <summary>Expected Delivery Date (calculated from LMP or set by provider)</summary>
    public DateTime? ExpectedDeliveryDate { get; set; }

    /// <summary>Number of previous pregnancies (Gravida)</summary>
    public int? Gravida { get; set; }

    /// <summary>Number of live births (Parity)</summary>
    public int? Parity { get; set; }

    /// <summary>High-risk pregnancy flag</summary>
    public bool IsHighRiskPregnancy { get; set; } = false;

    /// <summary>High-risk factors (JSON array)</summary>
    public string? HighRiskFactors { get; set; }
}
