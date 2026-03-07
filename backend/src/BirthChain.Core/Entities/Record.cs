namespace BirthChain.Core.Entities;

/// <summary>
/// Core medical record linking a client to a provider.
/// Append-only — no updates or deletes for audit trail.
/// </summary>
public class Record : BaseEntity
{
    public Guid ClientId { get; set; }
    public Guid ProviderId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // ═══════════════════════════════════════════════════════════════════════
    // Record Classification
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>
    /// Record type: Consultation, AntenatalVisit, Delivery, Immunization, 
    /// LabResult, Prescription, ChronicCareVisit, Emergency, Referral
    /// </summary>
    public string RecordType { get; set; } = "Consultation";

    /// <summary>Visit date (may differ from CreatedAt if record is added later)</summary>
    public DateTime VisitDate { get; set; } = DateTime.UtcNow;

    /// <summary>Facility where the visit occurred</summary>
    public string FacilityName { get; set; } = string.Empty;

    // ═══════════════════════════════════════════════════════════════════════
    // Clinical Information
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Chief complaint / reason for visit</summary>
    public string ChiefComplaint { get; set; } = string.Empty;

    /// <summary>Symptoms (JSON array or bullet-point text)</summary>
    public string Symptoms { get; set; } = string.Empty;

    /// <summary>Clinical examination findings</summary>
    public string Examination { get; set; } = string.Empty;

    /// <summary>Diagnosis (primary)</summary>
    public string Diagnosis { get; set; } = string.Empty;

    /// <summary>Secondary diagnoses (JSON array)</summary>
    public string? SecondaryDiagnoses { get; set; }

    /// <summary>Treatment provided</summary>
    public string Treatment { get; set; } = string.Empty;

    // ═══════════════════════════════════════════════════════════════════════
    // Vital Signs
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Blood pressure (e.g., "120/80")</summary>
    public string? BloodPressure { get; set; }

    /// <summary>Pulse rate (beats per minute)</summary>
    public int? PulseRate { get; set; }

    /// <summary>Temperature in Celsius</summary>
    public decimal? Temperature { get; set; }

    /// <summary>Weight in kg</summary>
    public decimal? Weight { get; set; }

    /// <summary>Height in cm</summary>
    public decimal? Height { get; set; }

    /// <summary>Oxygen saturation percentage</summary>
    public int? OxygenSaturation { get; set; }

    /// <summary>Respiratory rate (breaths per minute)</summary>
    public int? RespiratoryRate { get; set; }

    // ═══════════════════════════════════════════════════════════════════════
    // Maternal Health Fields (for AntenatalVisit, Delivery records)
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Gestational age in weeks at time of visit</summary>
    public int? GestationalWeeks { get; set; }

    /// <summary>Gestational age days (0-6)</summary>
    public int? GestationalDays { get; set; }

    /// <summary>Fundal height in cm</summary>
    public decimal? FundalHeight { get; set; }

    /// <summary>Fetal heart rate (beats per minute)</summary>
    public int? FetalHeartRate { get; set; }

    /// <summary>Fetal presentation: Cephalic, Breech, Transverse</summary>
    public string? FetalPresentation { get; set; }

    /// <summary>Fetal movement: Normal, Reduced, None</summary>
    public string? FetalMovement { get; set; }

    /// <summary>For delivery records: Mode of delivery</summary>
    public string? DeliveryMode { get; set; }

    /// <summary>For delivery records: Birth outcome</summary>
    public string? BirthOutcome { get; set; }

    /// <summary>For delivery records: Baby weight in grams</summary>
    public int? BabyWeightGrams { get; set; }

    /// <summary>For delivery records: APGAR score at 1 minute</summary>
    public int? ApgarScore1Min { get; set; }

    /// <summary>For delivery records: APGAR score at 5 minutes</summary>
    public int? ApgarScore5Min { get; set; }

    // ═══════════════════════════════════════════════════════════════════════
    // Medications & Lab Tests
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Medications prescribed (JSON array with name, dosage, frequency, duration)</summary>
    public string? Medications { get; set; }

    /// <summary>Lab tests ordered or results (JSON array)</summary>
    public string? LabTests { get; set; }

    /// <summary>Immunizations given (JSON array with vaccine name, batch, etc.)</summary>
    public string? Immunizations { get; set; }

    // ═══════════════════════════════════════════════════════════════════════
    // Plan & Follow-up
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Management plan / care instructions</summary>
    public string? CareInstructions { get; set; }

    /// <summary>Follow-up required: Yes/No</summary>
    public bool FollowUpRequired { get; set; } = false;

    /// <summary>Follow-up date if applicable</summary>
    public DateTime? FollowUpDate { get; set; }

    /// <summary>Referral to specialist/facility if needed</summary>
    public string? ReferralTo { get; set; }

    /// <summary>Additional notes (supports markdown formatting)</summary>
    public string? Notes { get; set; }

    // ═══════════════════════════════════════════════════════════════════════
    // Legacy field for backward compatibility
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>Legacy JSON description field (deprecated, kept for migration)</summary>
    public string Description { get; set; } = string.Empty;
}
