using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

/// <summary>
/// Health-check endpoint to verify the API is running.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok(new { status = "healthy", service = "BirthChain API" });
}
