namespace BirthChain.Core.Entities;

/// <summary>
/// Base class for all domain entities.
/// Provides a common identifier.
/// </summary>
public abstract class BaseEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
}
