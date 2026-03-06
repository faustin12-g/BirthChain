using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Provider,Admin,FacilityAdmin,Patient")]
public class ClientsController : ControllerBase
{
    private readonly IClientService _clientService;
    private readonly IActivityLogService _activityLog;

    public ClientsController(IClientService clientService, IActivityLogService activityLog)
    {
        _clientService = clientService;
        _activityLog = activityLog;
    }

    /// <summary>Patient: Get own client profile.</summary>
    [HttpGet("me")]
    [Authorize(Roles = "Patient")]
    public async Task<IActionResult> GetMyProfile()
    {
        var userId = Guid.Parse(User.FindFirstValue("sub")!);
        var client = await _clientService.GetByUserIdAsync(userId);
        if (client is null)
            return NotFound(new { message = "Patient profile not found." });
        return Ok(client);
    }

    /// <summary>Register a new client. QrCodeId is generated automatically.</summary>
    [HttpPost]
    [Authorize(Roles = "Provider")]
    public async Task<IActionResult> Create([FromBody] CreateClientDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.FullName))
            return BadRequest(new { message = "FullName is required." });

        var client = await _clientService.CreateAsync(dto);

        var userId = Guid.Parse(User.FindFirstValue("sub")!);
        await _activityLog.LogAsync(userId, $"Registered client {dto.FullName}");

        return CreatedAtAction(nameof(LookupByQrCode), new { qrCodeId = client.QrCodeId }, client);
    }

    /// <summary>Search clients by name, phone, email, or QR code.</summary>
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string q)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Ok(Array.Empty<ClientDto>());

        var results = await _clientService.SearchAsync(q);
        return Ok(results);
    }

    /// <summary>
    /// Look up a client by QR code. Returns limited info + hasPinSet flag.
    /// Use POST /clients/by-qr/{qrCodeId}/verify with PIN to get full access.
    /// </summary>
    [HttpGet("by-qr/{qrCodeId}")]
    public async Task<IActionResult> LookupByQrCode(string qrCodeId)
    {
        var lookup = await _clientService.LookupByQrCodeAsync(qrCodeId);
        if (lookup is null)
            return NotFound(new { message = $"No client found with QrCodeId '{qrCodeId}'." });
        return Ok(lookup);
    }

    /// <summary>
    /// Verify PIN and get full client data.
    /// Required if client has PIN set, otherwise returns data without PIN.
    /// </summary>
    [HttpPost("by-qr/{qrCodeId}/verify")]
    public async Task<IActionResult> VerifyPinAndGetClient(string qrCodeId, [FromBody] VerifyPinDto dto)
    {
        try
        {
            // First check if client exists and needs PIN
            var lookup = await _clientService.LookupByQrCodeAsync(qrCodeId);
            if (lookup is null)
                return NotFound(new { message = $"No client found with QrCodeId '{qrCodeId}'." });

            // If no PIN required, return full data
            if (!lookup.HasPinSet)
            {
                var clientData = await _clientService.GetByQrCodeAsync(qrCodeId);
                return Ok(clientData);
            }

            // PIN required - verify it
            if (string.IsNullOrWhiteSpace(dto.Pin))
                return BadRequest(new { message = "PIN is required to access this patient's data." });

            var client = await _clientService.GetByQrCodeWithPinAsync(qrCodeId, dto.Pin);
            if (client is null)
                return Unauthorized(new { message = "Invalid PIN." });

            var userId = Guid.Parse(User.FindFirstValue("sub")!);
            await _activityLog.LogAsync(userId, $"Accessed client {lookup.FullName} with PIN verification");

            return Ok(client);
        }
        catch (InvalidOperationException ex)
        {
            // PIN lockout or other validation error
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>List all clients.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var clients = await _clientService.GetAllAsync();
        return Ok(clients);
    }
}
