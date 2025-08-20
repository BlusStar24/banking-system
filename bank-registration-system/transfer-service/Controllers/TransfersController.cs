using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using transfer_service.DTOs;
using transfer_service.Services;

namespace transfer_service.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class TransfersController : ControllerBase
    {
        private readonly TransferService _transferService;

        public TransfersController(TransferService transferService)
        {
            _transferService = transferService;
        }

        [HttpPost("internal")]
        public async Task<IActionResult> InternalTransfer([FromBody] InternalTransferRequest request)
        {
            var userId = User.FindFirst("UserId")?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Thiếu hoặc sai token" });

            var result = await _transferService.InternalTransferAsync(request, userId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("external/request")]
        public async Task<IActionResult> ExternalTransferRequest([FromBody] ExternalTransferRequest request)
        {
            var userId = User.FindFirst("UserId")?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Thiếu hoặc sai token" });

            var result = await _transferService.ExternalTransferRequestAsync(request, userId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("external/settle")]
        public async Task<IActionResult> ExternalTransferSettle([FromBody] ExternalSettleRequest request)
        {
            var userId = User.FindFirst("UserId")?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Thiếu hoặc sai token" });

            var result = await _transferService.ExternalTransferSettleAsync(request, userId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("check")]
        public async Task<IActionResult> CheckCondition([FromBody] InternalTransferRequest req)
        {
            var result = await _transferService.CheckConditionAsync(req);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("verify")]
        public async Task<IActionResult> VerifyPin([FromBody] VerifyPinRequest req)
        {
            var valid = await _transferService.VerifyPinViaUserServiceAsync(
                req.OwnerType, // đúng thứ tự
                req.OwnerId,
                req.Pin
            );

            if (valid)
                return Ok(new { success = true, message = "Mã PIN đúng" });
            else
                return Ok(new { success = false, message = "Mã PIN sai hoặc tài khoản bị khóa" });
        }


        [HttpPost("generate")]
        public IActionResult GenerateOtp([FromBody] OtpRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.AccountId))
                return BadRequest(new { success = false, message = "AccountId required" });

            var otp = _transferService.GenerateOtp(request.AccountId);
            return Ok(new { success = true, otp }); // ⚠️ có thể bỏ trả về trong production
        }

        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp([FromBody] OtpVerifyRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.AccountId) || string.IsNullOrWhiteSpace(request.Code))
                return BadRequest(new { success = false, message = "AccountId và Code required" });

            var valid = _transferService.VerifyOtp(request.AccountId, request.Code);
            return Ok(new
            {
                success = valid,
                message = valid ? "OTP hợp lệ" : "OTP không đúng hoặc đã hết hạn"
            });
        }

        [HttpGet("otp/{accountId}")]
        [AllowAnonymous] // hoặc [Authorize] nếu cần bảo vệ
        public IActionResult PeekOtp(string accountId)
        {
            var otp = _transferService.PeekOtp(accountId);
            return Ok(new { otp });
        }

        [AllowAnonymous]
        [HttpPost("check-beneficiary")]
        public IActionResult CheckBeneficiary([FromBody] CheckBeneficiaryRequest req)
        {
            bool valid = _transferService.CheckBeneficiary(req.ToBankId, req.ToExternalRef, req.CounterpartyName);
            return Ok(new { success = valid });
        }

        [AllowAnonymous]
        [HttpPost("name-enquiry")]
        public async Task<IActionResult> NameEnquiry([FromBody] NameEnquiryRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.ToBankId))
            {
                var (name, accId) = await _transferService.GetInternalAccountInfoAsync(req.ToExternalRef);
                return Ok(new { name, accountId = accId });
            }
            else
            {
                var name = _transferService.GetCounterpartyName(req.ToBankId, req.ToExternalRef);
                return Ok(new { name });
            }
        }


    }

    public class OtpRequest
    {
        public string AccountId { get; set; } = string.Empty;
    }

    public class OtpVerifyRequest
    {
        public string AccountId { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
    public class NameEnquiryRequest
    {
        public string? ToBankId { get; set; } = null;
        public string ToExternalRef { get; set; } = string.Empty;
    }

}
