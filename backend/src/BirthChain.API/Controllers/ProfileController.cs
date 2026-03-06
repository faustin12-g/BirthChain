using System.Security.Claims;
using BirthChain.Application.DTOs;
using BirthChain.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BirthChain.API.Controllers;

/// <summary>
/// Profile management endpoints for all authenticated users.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly IProfileService _profileService;

    public ProfileController(IProfileService profileService)
    {
        _profileService = profileService;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue("sub")!);

    /// <summary>GET api/profile — Get current user's profile</summary>
    [HttpGet]
    public async Task<IActionResult> GetProfile()
    {
        var profile = await _profileService.GetProfileAsync(CurrentUserId);
        return profile is null
            ? NotFound(new { message = "Profile not found." })
            : Ok(profile);
    }

    /// <summary>PUT api/profile — Update profile information</summary>
    [HttpPut]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto dto)
    {
        try
        {
            var profile = await _profileService.UpdateProfileAsync(CurrentUserId, dto);
            return Ok(profile);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>PUT api/profile/image — Update profile image</summary>
    [HttpPut("image")]
    public async Task<IActionResult> UpdateProfileImage([FromBody] ProfileImageDto dto)
    {
        try
        {
            var profile = await _profileService.UpdateProfileImageAsync(CurrentUserId, dto);
            return Ok(profile);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>DELETE api/profile/image — Remove profile image</summary>
    [HttpDelete("image")]
    public async Task<IActionResult> RemoveProfileImage()
    {
        try
        {
            await _profileService.RemoveProfileImageAsync(CurrentUserId);
            return Ok(new { message = "Profile image removed." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>PUT api/profile/password — Change password</summary>
    [HttpPut("password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.CurrentPassword) || string.IsNullOrWhiteSpace(dto.NewPassword))
            return BadRequest(new { message = "Current and new passwords are required." });

        try
        {
            await _profileService.ChangePasswordAsync(CurrentUserId, dto);
            return Ok(new { message = "Password changed successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PIN Security Endpoints
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>GET api/profile/pin/status — Get PIN status (has PIN, is locked)</summary>
    [HttpGet("pin/status")]
    public async Task<IActionResult> GetPinStatus()
    {
        try
        {
            var status = await _profileService.GetPinStatusAsync(CurrentUserId);
            return Ok(status);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>POST api/profile/pin — Set PIN for the first time</summary>
    [HttpPost("pin")]
    public async Task<IActionResult> SetPin([FromBody] SetPinDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Pin))
            return BadRequest(new { message = "PIN is required." });

        try
        {
            await _profileService.SetPinAsync(CurrentUserId, dto);
            return Ok(new { message = "PIN set successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>PUT api/profile/pin — Change existing PIN</summary>
    [HttpPut("pin")]
    public async Task<IActionResult> ChangePin([FromBody] ChangePinDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.CurrentPin) || string.IsNullOrWhiteSpace(dto.NewPin))
            return BadRequest(new { message = "Current and new PINs are required." });

        try
        {
            await _profileService.ChangePinAsync(CurrentUserId, dto);
            return Ok(new { message = "PIN changed successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>DELETE api/profile/pin — Remove PIN</summary>
    [HttpDelete("pin")]
    public async Task<IActionResult> RemovePin([FromBody] VerifyPinDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Pin))
            return BadRequest(new { message = "Current PIN is required." });

        try
        {
            await _profileService.RemovePinAsync(CurrentUserId, dto.Pin);
            return Ok(new { message = "PIN removed successfully." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>POST api/profile/pin/verify — Verify PIN (for self-access)</summary>
    [HttpPost("pin/verify")]
    public async Task<IActionResult> VerifyPin([FromBody] VerifyPinDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Pin))
            return BadRequest(new { message = "PIN is required." });

        try
        {
            var isValid = await _profileService.VerifyPinAsync(CurrentUserId, dto.Pin);
            return Ok(new { valid = isValid });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
