using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Text;
using user_service.Data;
using user_service.DTOs;
using user_service.Models;
using BCrypt.Net;
using Microsoft.AspNetCore.Http;
using MySqlConnector;
using System.Security.Cryptography;

namespace user_service.Services
{
    public class UserService
    {
        private readonly UserDbContext _context;
        private readonly HttpClient _http;
        private readonly BonitaService _bonita;
        private readonly ILogger<UserService> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public UserService(
            UserDbContext context,
            IHttpClientFactory factory,
            BonitaService bonita,
            ILogger<UserService> logger,
            IHttpContextAccessor httpContextAccessor
        )
        {
            _context = context;
            _http = factory.CreateClient();
            _bonita = bonita;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
        }

        // ==========================================Các phương thức chính========================================== //

        // 1. Đăng ký Customer mới
        public async Task<Customer> RegisterCustomerAsync(RegisterRequest req)
        {
            var customer = new Customer
            {
                CustomerId = Guid.NewGuid().ToString(),
                Name = req.Name,
                Phone = req.Phone,
                CCCD = req.CCCD,
                Dob = req.Dob ?? DateTime.UtcNow,
                Gender = req.Gender ?? "other",
                Hometown = req.Hometown,
                Email = req.Email,
                Status = "pending",
                Blacklisted = false
            };

            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();

            return customer;
        }

        // 2. Verify OTP (sửa tham số dùng OtpVerifyDto)
        public async Task<string> VerifyOtpAsync(OtpVerifyDto dto)
        {
            // 1. Lấy thông tin khách hàng
            var customer = await _context.Customers.FirstOrDefaultAsync(c => c.Phone == dto.Phone);
            if (customer == null) return "Customer not found";

            // 2. Gọi OTP-service verify thay vì tự kiểm tra trong DB
            var json = JsonSerializer.Serialize(new
            {
                phone = dto.Phone,
                code = dto.Code
            });
            var content = new StringContent(json, Encoding.UTF8, "application/json");
            var response = await _http.PostAsync("http://otp-service:8080/api/otp/verify", content);

            if (!response.IsSuccessStatusCode)
            {
                return "OTP invalid or expired";
            }

            // 3. Cập nhật trạng thái khách hàng trong DB
            customer.Status = "verified";
            await _context.SaveChangesAsync();

            // 4. Gọi Bonita BPM nếu cần
            var result = await _bonita.StartProcessAsync(dto.SessionId, dto.CsrfToken, new Dictionary<string, string>
            {
                ["name"] = customer.Name,
                ["email"] = customer.Email ?? "",
                ["phone"] = customer.Phone,
                ["cccd"] = customer.CCCD,
                ["dob"] = customer.Dob.ToString("yyyy-MM-dd"),
                ["hometown"] = customer.Hometown ?? "",
                ["status"] = customer.Status,
                ["gender"] = customer.Gender
            });

            return result
                ? "OTP verified and process started"
                : "OTP verified, but failed to start Bonita process";
        }


        // 3. Blacklist
        public async Task<List<string>> GetBlacklistAsync()
        {
            return await _context.Blacklists   // sửa tên DbSet
                .Select(b => b.CustomerId)
                .ToListAsync();
        }

        // 4. Tạo User login
        public async Task<User> CreateUserAsync(CreateUserDto dto)
        {
            var user = new User
            {
                Username = dto.Username,
                PasswordHash = dto.PasswordHash,
                Role = dto.Role,
                LinkedCustomerId = dto.LinkedCustomerId
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return user;
        }

        // ===== CIF: sinh nhanh + retry nếu trùng, lưu ngay không báo lỗi =====

        private static string NewCifCandidate()
        {
            // CIF + 6 chữ số
            Span<byte> bytes = stackalloc byte[4];
            RandomNumberGenerator.Fill(bytes);
            var num = BitConverter.ToUInt32(bytes) % 900000 + 100000;
            return $"CIF{num}";
        }

        private static bool IsDuplicateKey(DbUpdateException ex)
        {
            // Pomelo + MySqlConnector: duplicate key = 1062
            return ex.InnerException is MySqlException my && my.Number == 1062;
        }

        private async Task EnsureUniqueCifAsync(Customer customer, int maxRetries = 5)
        {
            if (!string.IsNullOrWhiteSpace(customer.Cif))
                return;

            for (int attempt = 1; attempt <= maxRetries; attempt++)
            {
                customer.Cif = NewCifCandidate();

                try
                {
                    // chỉ đánh dấu Cif thay đổi để save nhanh
                    _context.Entry(customer).Property(c => c.Cif).IsModified = true;
                    await _context.SaveChangesAsync();
                    return; // OK
                }
                catch (DbUpdateException ex) when (IsDuplicateKey(ex))
                {
                    // Trùng -> thử lại, không throw
                    customer.Cif = null;
                    await Task.Delay(15 * attempt); // backoff nhẹ
                }
            }

            // fallback rất hiếm khi cần
            customer.Cif = $"{NewCifCandidate()}A";
            _context.Entry(customer).Property(c => c.Cif).IsModified = true;
            await _context.SaveChangesAsync();
        }

        // 5. *** Tạo tài khoản Core Banking + gửi email thông báo ***
        public async Task<CreateCoreAccountResponse> CreateCoreAccountAsync(CreateCoreAccountRequest req)
        {
            // 1. Lấy thông tin khách hàng
            var customer = await _context.Customers.FirstOrDefaultAsync(c => c.CustomerId == req.CustomerId);
            if (customer == null) throw new Exception("Customer not found");

            // 2. CIF: gán nhanh, trùng tự retry, lưu ngay
            await EnsureUniqueCifAsync(customer);
            var cif = customer.Cif!;

            // 3. Xử lý số tài khoản
            string accountNumber = "";
            if (!string.IsNullOrWhiteSpace(req.AccountNumber))
            {
                accountNumber = req.AccountNumber.Trim();
            }
            else
            {
                var ctx = _httpContextAccessor?.HttpContext;
                var fromHeader = ctx?.Request.Headers["X-Account-Number"].FirstOrDefault();
                var fromQuery = ctx?.Request.Query["accountNumber"].FirstOrDefault();
                accountNumber = (fromHeader ?? fromQuery ?? "").Trim();
            }

            if (!string.IsNullOrWhiteSpace(accountNumber))
            {
                bool exists = await _context.Accounts.AnyAsync(a => a.AccountNumber == accountNumber);
                if (exists) throw new Exception("Số tài khoản đã tồn tại, vui lòng chọn số khác");
            }
            else
            {
                // Sinh ngẫu nhiên và kiểm tra trùng
                var rnd = new Random();
                do
                {
                    accountNumber = $"9704{rnd.Next(100000000, 999999999)}";
                } while (await _context.Accounts.AnyAsync(a => a.AccountNumber == accountNumber));
            }

            // validate độ dài để tránh lỗi Substring
            if (accountNumber.Length < 4)
                throw new Exception("Số tài khoản không hợp lệ");

            // 4. Tạo tài khoản
            var account = new Account
            {
                CustomerId = customer.CustomerId,
                Type = req.AccountType,
                Label = $"Tài khoản {req.AccountType}",
                Balance = req.InitialBalance,
                BankCode = accountNumber.Substring(0, 4),
                AccountNumber = accountNumber,
                Status = "active"
            };

            _context.Accounts.Add(account);
            customer.Status = "active";
            await _context.SaveChangesAsync();

            // 5. Tạo user login nếu chưa có (giữ nguyên)
            var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.LinkedCustomerId == customer.CustomerId);
            if (existingUser == null)
            {
                var userDto = new CreateUserDto
                {
                    Username = customer.CCCD,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
                    Role = "customer",
                    LinkedCustomerId = customer.CustomerId
                };
                await CreateUserAsync(userDto);
            }

            // 6. Gửi email thông báo (cập nhật nội dung dùng CIF đã lưu)
            var emailPayload = new
            {
                Email = customer.Email,
                Subject = "Tài khoản ngân hàng đã được mở thành công",
                Body = $"Xin chào {customer.Name},\n\n" +
                       $"Tài khoản ngân hàng của bạn đã được tạo thành công.\n" +
                       $"CIF: {cif}\nSố tài khoản: {accountNumber}\n" +
                       $"Tên đăng nhập: {customer.CCCD}\nMật khẩu mặc định: 123456"
            };

            var content = new StringContent(JsonSerializer.Serialize(emailPayload), Encoding.UTF8, "application/json");
            var response = await _http.PostAsync("http://email-service:8080/api/email/send", content);
            if (!response.IsSuccessStatusCode)
                throw new Exception($"Email-service gửi thông báo thất bại: {response.StatusCode}");

            // 7. Trả về response
            return new CreateCoreAccountResponse
            {
                CIF = cif,
                AccountNumber = accountNumber,
                CustomerEmail = customer.Email ?? "",
                CustomerPhone = customer.Phone
            };
        }


        // 5. Kiểm tra số tài khoản đã tồn tại chưa
        public async Task<bool> CheckAccountNumberExistsAsync(string accountNumber)
        {
            return await _context.Accounts.AnyAsync(a => a.AccountNumber == accountNumber);
        }

        // 6. Lấy thông tin người dùng theo username
        public async Task<UserProfileDto?> GetUserByUsernameAsync(string username)
        {
            var user = await _context.Users
                .Include(u => u.LinkedCustomer)
                    .ThenInclude(c => c.Accounts)
                .FirstOrDefaultAsync(u => u.Username == username);

            if (user == null || user.LinkedCustomer == null)
                return null;

            var customer = user.LinkedCustomer;
            var account = customer.Accounts?.FirstOrDefault();

            return new UserProfileDto
            {
                Username = user.Username,
                Role = user.Role,
                LinkedCustomerId = user.LinkedCustomerId!,

                Customer = new CustomerDto
                {
                    CustomerId = customer.CustomerId,
                    Name = customer.Name,
                    CCCD = customer.CCCD,
                    Email = customer.Email!,
                    Phone = customer.Phone,
                    Dob = customer.Dob,
                    Hometown = customer.Hometown!,
                    Status = customer.Status
                },

                Account = account == null ? null : new AccountDto
                {
                    AccountId = account.AccountId,
                    AccountNumber = account.AccountNumber!,
                    Balance = account.Balance,
                    Type = account.Type,
                    CreatedAt = account.CreatedAt
                }
            };
        }

        // 7. Kiểm tra đăng nhập
        public async Task<User?> LoginAsync(string username, string password)
        {
            var user = await _context.Users
                .Include(u => u.LinkedCustomer)
                .FirstOrDefaultAsync(u =>
                    u.Username == username ||
                    (u.LinkedCustomer != null && (
                        u.LinkedCustomer.Phone == username ||
                        u.LinkedCustomer.CCCD == username
                    )));

            if (user == null) return null;

            bool valid = BCrypt.Net.BCrypt.Verify(password, user.PasswordHash);
            return valid ? user : null;
        }
        // 8. Quên mật khẩu
        public async Task<string> ForgotPasswordAsync(ForgotPasswordRequest req)
        {
            // 1. Tìm customer theo CCCD và email
            var customer = await _context.Customers
                .FirstOrDefaultAsync(c => c.CCCD == req.CCCD && c.Email == req.Email);

            if (customer == null)
                return "Không tìm thấy khách hàng hoặc email không đúng";

            // 2. Kiểm tra phone tương ứng với customer
            if (customer.Phone != req.Phone)
                return "Số điện thoại không khớp với khách hàng";

            // 3. Tìm user tương ứng
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.LinkedCustomerId == customer.CustomerId);

            if (user == null)
                return "Không tìm thấy tài khoản người dùng";

            // 4. Sinh mật khẩu mới
            var newPassword = GenerateRandomPassword();
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            await _context.SaveChangesAsync();

            // 5. Gửi email
            var emailPayload = new
            {
                Email = req.Email,
                Subject = "Khôi phục mật khẩu đăng nhập",
                Body = $"Xin chào {customer.Name},\n\n" +
                       $"Mật khẩu mới của bạn là: {newPassword}\n" +
                       $"Vui lòng đăng nhập và đổi mật khẩu ngay sau khi vào hệ thống."
            };

            var content = new StringContent(JsonSerializer.Serialize(emailPayload), Encoding.UTF8, "application/json");
            var response = await _http.PostAsync("http://email-service:8080/api/email/send", content);

            if (!response.IsSuccessStatusCode)
                return "Không gửi được email. Vui lòng thử lại sau.";
            _logger.LogInformation("🔐 Mật khẩu mới: {NewPassword}", newPassword);
            return "Mật khẩu mới đã được gửi về email của bạn.";
        }

        private string GenerateRandomPassword()
        {
            const string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
            return new string(Enumerable.Repeat(chars, 8).Select(s => s[new Random().Next(s.Length)]).ToArray());
        }

        // 9. Đổi mật khẩu
        public async Task<string> ChangePasswordAsync(ChangePasswordRequest req)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.LinkedCustomerId == req.CustomerId);
            if (user == null)
                return "Không tìm thấy tài khoản.";

            if (!BCrypt.Net.BCrypt.Verify(req.OldPassword, user.PasswordHash))
                return "Mật khẩu cũ không đúng.";

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
            await _context.SaveChangesAsync();

            return "Đổi mật khẩu thành công.";
        }


        private string GenerateOtp()
        {
            var rand = new Random();
            return rand.Next(100000, 999999).ToString();
        }
        //=============================================pin=========================================
        //set mã pin
        public async Task<string> SetPinAsync(string ownerType, string ownerId, string pin)
        {
            // Kiểm tra định dạng mã PIN
            if (string.IsNullOrWhiteSpace(pin) || pin.Length != 6 || !pin.All(char.IsDigit))
                return "Mã PIN phải gồm đúng 6 chữ số.";

            // Băm mã PIN
            var pinHash = BCrypt.Net.BCrypt.HashPassword(pin);

            // Kiểm tra đã có PIN chưa
            var existing = await _context.PinCodes
                .FirstOrDefaultAsync(p => p.OwnerType == ownerType && p.OwnerId == ownerId);

            if (existing == null)
            {
                var newPin = new PinCode
                {
                    OwnerType = ownerType,
                    OwnerId = ownerId,
                    PinHash = pinHash,
                    FailedAttempts = 0,
                    IsLocked = false,
                    LastChanged = DateTime.UtcNow
                };
                _context.PinCodes.Add(newPin);
            }
            else
            {
                existing.PinHash = pinHash;
                existing.FailedAttempts = 0;
                existing.IsLocked = false;
                existing.LastChanged = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return "Mã PIN đã được thiết lập thành công.";
        }

        public async Task<string> SetPinAccountAsync(string accountId, string pin)
        {
            return await SetPinAsync("account", accountId, pin);
        }

        public async Task<string> SetPinCardAsync(string cardId, string pin)
        {
            return await SetPinAsync("card", cardId, pin);
        }

        public async Task<bool> VerifyPinAsync(string ownerType, string ownerId, string plainPin)
        {
            _logger.LogInformation("VerifyPinAsync called with ownerType={OwnerType}, ownerId={OwnerId}, pin={Pin}",
                ownerType, ownerId, plainPin);

            var record = await _context.PinCodes
                .FirstOrDefaultAsync(p => p.OwnerType == ownerType && p.OwnerId == ownerId);

            if (record == null)
            {
                _logger.LogWarning("Không tìm thấy bản ghi mã PIN cho {OwnerType}:{OwnerId}", ownerType, ownerId);
                return false;
            }

            if (record.IsLocked)
            {
                _logger.LogWarning("Mã PIN cho {OwnerId} đang bị khóa", ownerId);
                return false;
            }

            bool valid = BCrypt.Net.BCrypt.Verify(plainPin, record.PinHash);
            _logger.LogInformation("So sánh mã PIN: {Result}", valid);

            if (valid)
            {
                record.FailedAttempts = 0;
                await _context.SaveChangesAsync();
                return true;
            }
            else
            {
                record.FailedAttempts++;
                if (record.FailedAttempts >= 3)
                {
                    record.IsLocked = true;
                    _logger.LogWarning("Mã PIN bị khóa sau 3 lần sai: {OwnerId}", ownerId);
                }

                await _context.SaveChangesAsync();
                return false;
            }
        }


        public async Task<bool> VerifyPinAccountAsync(string accountId, string pin)
        {
            return await VerifyPinAsync("account", accountId, pin);
        }

        public async Task<bool> HasPinAsync(string ownerType, string ownerId)
        {
            return await _context.PinCodes
                .AnyAsync(p => p.OwnerType == ownerType && p.OwnerId == ownerId && !p.IsLocked);
        }

    }
}
