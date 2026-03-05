using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Provider,Admin")]
public class ClientsController : ControllerBase
{
    private readonly IClientService _clientService;
    private readonly IActivityLogService _activityLog;

    public ClientsController(IClientService clientService, IActivityLogService activityLog)
    {
        _clientService = clientService;
        _activityLog = activityLog;
    }

    /// <summary>Register a new client. QrCodeId is generated automatically.</summary>
    [HttpPost]
    [Authorize(Roles = "Provider")]
    public async Task<IActionResult> Create([FromBody] CreateClientDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.FullName))
            return BadRequest(new { message = "FullName is required." });

        var client = await _clientService.CreateAsync(dto);

        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await _activityLog.LogAsync(userId, $"Registered client {dto.FullName}");

        return CreatedAtAction(nameof(GetByQrCode), new { qrCodeId = client.QrCodeId }, client);
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

    /// <summary>Look up a client by QR code.</summary>
    [HttpGet("by-qr/{qrCodeId}")]
    public async Task<IActionResult> GetByQrCode(string qrCodeId)
    {
        var client = await _clientService.GetByQrCodeAsync(qrCodeId);
        if (client is null)
            return NotFound(new { message = $"No client found with QrCodeId '{qrCodeId}'." });
        return Ok(client);
    }

    /// <summary>List all clients.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var clients = await _clientService.GetAllAsync();
        return Ok(clients);
    }
}
