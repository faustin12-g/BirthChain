using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Provider,Admin")]
public class RecordsController : ControllerBase
{
    private readonly IRecordService _recordService;
    private readonly IClientService _clientService;

    public RecordsController(IRecordService recordService, IClientService clientService)
    {
        _recordService = recordService;
        _clientService = clientService;
    }

    /// <summary>Append a new record for a client. Provider is resolved from the JWT.</summary>
    [HttpPost]
    [Authorize(Roles = "Provider")]
    public async Task<IActionResult> Create([FromBody] CreateRecordDto dto)
    {
        if (dto.ClientId == Guid.Empty)
            return BadRequest(new { message = "ClientId is required." });
        if (string.IsNullOrWhiteSpace(dto.Description))
            return BadRequest(new { message = "Description is required." });

        var providerUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        try
        {
            var record = await _recordService.CreateAsync(providerUserId, dto);
            return CreatedAtAction(nameof(GetByClient), new { clientId = dto.ClientId }, record);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Get all records for a client.</summary>
    [HttpGet("by-client/{clientId:guid}")]
    public async Task<IActionResult> GetByClient(Guid clientId)
    {
        var client = await _clientService.GetByIdAsync(clientId);
        if (client is null)
            return NotFound(new { message = $"Client '{clientId}' not found." });

        var records = await _recordService.GetByClientIdAsync(clientId);
        return Ok(new { client, records });
    }

    /// <summary>Get all records for a client via QR code.</summary>
    [HttpGet("by-qr/{qrCodeId}")]
    public async Task<IActionResult> GetByQrCode(string qrCodeId)
    {
        var client = await _clientService.GetByQrCodeAsync(qrCodeId);
        if (client is null)
            return NotFound(new { message = $"No client with QrCodeId '{qrCodeId}'." });

        var records = await _recordService.GetByClientIdAsync(client.Id);
        return Ok(new { client, records });
    }
}
