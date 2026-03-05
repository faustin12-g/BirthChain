namespace BirthChain.Core.Exceptions;

/// <summary>
/// Thrown when a domain rule is violated.
/// </summary>
public class DomainException : Exception
{
    public DomainException(string message) : base(message) { }
}
