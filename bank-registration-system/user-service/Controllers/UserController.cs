using Microsoft.AspNetCore.Mvc;
using user_service.DTOs;
using user_service.Services;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using StackExchange.Redis;
using Microsoft.AspNetCore.Http;

namespace user_service.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/customers")]
    public class UserController : ControllerBase
    {
        private readonly IConfiguration _config;
        private readonly UserService _service;
        private readonly ILogger<UserController> _logger;
        private readonly AuthService _authService;

        public UserController(IConfiguration config, UserService service, ILogger<UserController> logger, AuthService authService)
        {
            _authService = authService;
            _logger = logger;
            _service = service;
            _config = config;
        }
        [AllowAnonymous]
        // Đăng ký khách hàng (chỉ lưu DB)
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest req)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var customer = await _service.RegisterCustomerAsync(req);
            return Ok(new { message = "Đã đăng ký, vui lòng bấm gửi OTP để xác thực", customer_id = customer.CustomerId });
        }

        [AllowAnonymous]
        // 2. Xác thực OTP
        [HttpPost("verify")]
        public async Task<IActionResult> VerifyOtp([FromBody] OtpVerifyDto dto)
        {
            var result = await _service.VerifyOtpAsync(dto);
            return Ok(new { message = result });
        }

        [AllowAnonymous]
        // 3. Lấy blacklist
        [HttpGet("blacklist")]
        public async Task<IActionResult> GetBlacklist()
        {
            var list = await _service.GetBlacklistAsync();
            return Ok(list);
        }
        //====================================================Core Banking=========================================
        [AllowAnonymous]
        // 4. Tạo tài khoản Core Banking (gọi UserService)
        [HttpPost("create-core-account")]
        public async Task<IActionResult> CreateCoreAccount([FromBody] CreateCoreAccountRequest req)
        {
            var account = await _service.CreateCoreAccountAsync(req);

            return Ok(new
            {
                message = "Tạo tài khoản thành công",
                cif = account.CIF,
                accountNumber = account.AccountNumber
            });
        }
        [AllowAnonymous]
        [HttpGet("check-account-number/{accountNumber}")]
        public async Task<IActionResult> CheckAccountNumber(string accountNumber)
        {
            var exists = await _service.CheckAccountNumberExistsAsync(accountNumber);
            return Ok(new { exists });
        }
        //====================================================Authentication=========================================
        [AllowAnonymous]
        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] TokenDto dto)
        {
            var result = await _authService.RefreshTokenAsync(dto);
            if (result == null)
                return Unauthorized(new { message = "Token không hợp lệ hoặc đã hết hạn" });
            return Ok(result);
        }
        [AllowAnonymous]
        // 5. Kiểm tra login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest dto, [FromServices] IConnectionMultiplexer redis)
        {
            var user = await _service.LoginAsync(dto.Username, dto.Password);
            if (user == null)
                return Unauthorized(new { message = "Sai tên đăng nhập hoặc mật khẩu" });

            var tokens = await _authService.GenerateTokensAsync(user);
            var db = redis.GetDatabase();
            var key = $"last_active:{user.UserId}";
            await db.StringSetAsync(key, "active", TimeSpan.FromMinutes(30));
            return Ok(new
            {
                accessToken = tokens.AccessToken,
                refreshToken = tokens.RefreshToken,
                username = user.Username,
                customer = user.LinkedCustomer,
                account = user.LinkedCustomer?.Accounts?.FirstOrDefault()
            });
        }

        [Authorize]
        [HttpGet("ping")]
        public async Task<IActionResult> Ping([FromServices] IConnectionMultiplexer redis)
        {
            var userId = User.FindFirst("UserId")?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var db = redis.GetDatabase();
            var key = $"last_active:{userId}";
            await db.StringSetAsync(key, "active", TimeSpan.FromMinutes(10));

            return Ok(new { message = "pong" });
        }


        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            var userId = User.FindFirst("UserId")?.Value;
            if (userId == null) return Unauthorized();

            await _authService.RevokeRefreshTokenAsync(userId);  // viết thêm hàm này
            return Ok(new { message = "Đăng xuất thành công" });
        }

        // 6. Lấy thông tin token user theo username
        [Authorize]
        [HttpGet("user-profile")]
        public async Task<IActionResult> GetProfile()
        {
            var username = User.FindFirst(ClaimTypes.Name)?.Value
                ?? User.FindFirst("name")?.Value
                ?? User.Identity?.Name;
            _logger.LogInformation("Username extracted from token: {Username}", username);
            _logger.LogInformation("All claims: {Claims}",
                string.Join(", ", User.Claims.Select(c => $"{c.Type}: {c.Value}")));
            if (string.IsNullOrEmpty(username))
            {
                _logger.LogWarning("Không lấy được username từ token.");
                return Unauthorized(new { message = "Không lấy được username từ token" });
            }

            var user = await _service.GetUserByUsernameAsync(username);
            if (user == null)
            {
                _logger.LogWarning("Không tìm thấy user với username: {Username}", username);
                return NotFound(new { message = "Không tìm thấy người dùng" });
            }
            return Ok(user);
        }

        // 7. Quên mật khẩu - gửi mật khẩu mới qua email
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest req)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Console.WriteLine($"Authenticated userId: {userId}");
            
            var result = await _service.ForgotPasswordAsync(req);
            _logger.LogInformation("Quên mật khẩu: {Message}", result);
            return Ok(new { message = result });
        }

        // 8. Đổi mật khẩu
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest req)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Console.WriteLine($"Authenticated userId: {userId}");

            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Không xác định được người dùng từ token");

            var result = await _service.ChangePasswordAsync(req);
            return Ok(new { message = result });
        }

        // 9. Thiết lập mã PIN
        [HttpPost("set-pin")]
        public async Task<IActionResult> SetPin([FromBody] SetPinRequest req)
        {
            var result = await _service.SetPinAsync(req.OwnerType, req.OwnerId, req.Pin);
            return Ok(new { message = result });
        }

        [HttpPost("verify-pin")]
        public async Task<IActionResult> VerifyPin([FromBody] VerifyPinRequest req)
        {
            var result = await _service.VerifyPinAsync(req.OwnerType, req.OwnerId, req.Pin);
            return Ok(new { valid = result });
        }

        [HttpGet("has-pin")]
        [Authorize]
        public async Task<IActionResult> HasPin([FromQuery] string ownerType, [FromQuery] string ownerId)
        {
            var exists = await _service.HasPinAsync(ownerType, ownerId);
            return Ok(new { hasPin = exists });
        }

    }
}
