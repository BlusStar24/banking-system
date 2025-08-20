using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging; // Bắt buộc phải có để dùng ILogger
using System.ComponentModel.DataAnnotations;
using System.Linq;

[ApiController]
[Route("api/[controller]")]
public class OtpController : ControllerBase
{
    private readonly RedisOtpService _otpService;
    private readonly ILogger<OtpController> _logger; 

    // Inject logger vào constructor
    public OtpController(RedisOtpService otpService, ILogger<OtpController> logger)
    {
        _otpService = otpService;
        _logger = logger;
    }

    [HttpPost("send")]
    public IActionResult SendOtp([FromBody] OtpSendRequest req)
    {
       _logger.LogInformation("Received: phone={Phone}, method={Method}, email={Email}", req.Phone, req.Method, req.Email);

        if (!ModelState.IsValid)
        {
            _logger.LogWarning("ModelState INVALID:");
            var errors = ModelState
                .Where(x => x.Value.Errors.Count > 0)
                .Select(kvp => new {
                    Field = kvp.Key,
                    Errors = kvp.Value.Errors.Select(e => e.ErrorMessage).ToArray()
                }).ToList();

            foreach (var err in errors)
            {
                _logger.LogWarning(" - Field `{Field}`: {Errors}", err.Field, string.Join(", ", err.Errors));
            }

            return BadRequest(new { message = "Dữ liệu không hợp lệ", errors });
        }

        if (req.Method != "email" && req.Method != "sms")
        {
            _logger.LogError("Method không hợp lệ: {Method}", req.Method);
            return BadRequest(new { message = "Phương thức OTP không hợp lệ. Chọn 'email' hoặc 'sms'." });
        }

        if (req.Method == "email" && string.IsNullOrEmpty(req.Email))
        {
            _logger.LogError("Chọn email nhưng không truyền Email.");
            return BadRequest(new { message = "Email là bắt buộc khi chọn phương thức email." });
        }

        _logger.LogInformation("Dữ liệu hợp lệ. Gửi OTP tới {Phone} qua {Method}", req.Phone, req.Method);

        _otpService.Send(req.Phone, req.Email, req.Method);

        return Ok(new { message = "OTP sent" });
    }

   [HttpPost("verify")]
    public IActionResult VerifyOtp([FromBody] OtpRequest req)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { otpVerified = false, message = "Dữ liệu không hợp lệ", errors = ModelState });
        }

        var result = _otpService.Verify(req.Phone, req.Code);

        if (result)
        {
            return Ok(new { otpVerified = true, message = "OTP verified" });
        }
        else
        {
            return BadRequest(new { otpVerified = false, message = "Invalid OTP" });
        }
    }

}

public class OtpSendRequest
{
    [Required(ErrorMessage = "Phone is required")]
    public string Phone { get; set; }

    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; } // Không yêu cầu bắt buộc

    [Required(ErrorMessage = "Method is required")]
    public string Method { get; set; }
}

public class OtpRequest
{
    [Required(ErrorMessage = "Phone is required")]
    public string Phone { get; set; }

    [Required(ErrorMessage = "Code is required")]
    public string Code { get; set; }
}