namespace BirthChain.Core.Entities;

/// <summary>
/// Patient reminders for appointments, medications, and follow-ups.
/// </summary>
public class Reminder : BaseEntity
{
    public Guid ClientId { get; set; }
    public Guid? ProviderId { get; set; }

    /// <summary>Reminder type: Appointment, Medication, FollowUp, Immunization, Antenatal</summary>
    public string ReminderType { get; set; } = "Appointment";

    /// <summary>Title of the reminder</summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>Detailed message</summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>Scheduled date/time for the reminder</summary>
    public DateTime ScheduledDate { get; set; }

    /// <summary>When to send notification (e.g., 1 day before, 1 hour before)</summary>
    public int NotifyBeforeMinutes { get; set; } = 1440; // Default: 1 day before

    /// <summary>Is this a recurring reminder</summary>
    public bool IsRecurring { get; set; } = false;

    /// <summary>Recurrence pattern: Daily, Weekly, Monthly, Custom</summary>
    public string? RecurrencePattern { get; set; }

    /// <summary>Status: Pending, Sent, Completed, Cancelled</summary>
    public string Status { get; set; } = "Pending";

    /// <summary>Date when notification was sent</summary>
    public DateTime? SentAt { get; set; }

    /// <summary>Date when marked as completed</summary>
    public DateTime? CompletedAt { get; set; }

    /// <summary>Reference to related record if applicable</summary>
    public Guid? RelatedRecordId { get; set; }

    /// <summary>Facility name for the appointment</summary>
    public string? FacilityName { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
