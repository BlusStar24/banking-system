using Microsoft.Extensions.Caching.Memory;
using MySql.Data.MySqlClient;
using System.Data;
using System.Text;
using System.Text.Json;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using StackExchange.Redis;
using transfer_service.DTOs;


namespace transfer_service.Services
{
    public class TransferService
    {
        private readonly IDatabase _redis;
        private readonly IConfiguration _config;
        private readonly ILogger<TransferService> _logger;
        private readonly HttpClient _http;
        private readonly IMemoryCache _cache;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly List<(string BankId, string ExternalRef, string Name)> _allowedBeneficiaries
       = new List<(string, string, string)>();

        public TransferService(
           IConnectionMultiplexer connectionMultiplexer,
            IConfiguration config,
            ILogger<TransferService> logger,
            HttpClient http,
            IMemoryCache cache,
            IHttpContextAccessor httpContextAccessor)
        {
            _redis = connectionMultiplexer.GetDatabase();
            _config = config;
            _logger = logger;
            _http = http;
            _cache = cache;
            _httpContextAccessor = httpContextAccessor;
            var csvPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Data", "external_accounts_mock.csv");
            LoadAllowedBeneficiaries(csvPath);
        }
        // Hàm nạp danh sách người nhận hợp lệ từ file CSV
        // Dữ liệu mẫu: toBankId_ct,toExternalRef_ct,counterpartyName
        private void LoadAllowedBeneficiaries(string csvFilePath)
        {
            if (!File.Exists(csvFilePath))
                throw new FileNotFoundException($"CSV file not found: {csvFilePath}");

            using var reader = new StreamReader(csvFilePath);
            string? line;
            bool isHeader = true;
            while ((line = reader.ReadLine()) != null)
            {
                if (isHeader) { isHeader = false; continue; } // bỏ header
                var parts = line.Split(',');
                if (parts.Length >= 3)
                {
                    _allowedBeneficiaries.Add((parts[0].Trim(), parts[1].Trim(), parts[2].Trim().ToUpper()));
                }
            }
        }
        // Hàm kiểm tra xem người nhận có hợp lệ không
        public bool CheckBeneficiary(string bankId, string extRef, string name)
        {
            return _allowedBeneficiaries.Any(b =>
                b.BankId.Equals(bankId, StringComparison.OrdinalIgnoreCase) &&
                b.ExternalRef.Equals(extRef, StringComparison.OrdinalIgnoreCase) &&
                b.Name.Equals(name.Trim().ToUpper(), StringComparison.OrdinalIgnoreCase)
            );
        }
        // Hàm lấy tên đối tác từ danh sách đã cho
        public string? GetCounterpartyName(string bankId, string extRef)
        {
            return _allowedBeneficiaries
                .FirstOrDefault(b =>
                    b.BankId.Equals(bankId, StringComparison.OrdinalIgnoreCase) &&
                    b.ExternalRef.Equals(extRef, StringComparison.OrdinalIgnoreCase))
                .Name;
        }
        public async Task<(string? Name, string? AccountId)> GetInternalAccountInfoAsync(string accountNumber)
        {
            await using var conn = NewConn();
            await conn.OpenAsync();

            using var cmd = new MySqlCommand(@"
                SELECT c.name, a.account_id
                FROM accounts a
                JOIN customers c ON a.customer_id = c.customer_id
                WHERE a.account_number = @acc
                LIMIT 1", conn);

            cmd.Parameters.AddWithValue("@acc", accountNumber);

            using var reader = await cmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                var name = reader.GetString(0);
                var accId = reader.GetString(1);
                return (name, accId);
            }

            return (null, null);
        }


        // Hàm xác minh mã PIN từ user-service
        private MySqlConnection NewConn()
            => new MySqlConnection(_config.GetConnectionString("BankDb"));
        // Hàm xác minh mã PIN từ user-service
        private async Task<bool> IsSenderBlacklistedAsync(MySqlConnection conn, string fromAccountId)
        {
            using var cmd1 = new MySqlCommand(
                "SELECT customer_id FROM accounts WHERE account_id=@acc LIMIT 1", conn);
            cmd1.Parameters.AddWithValue("@acc", fromAccountId);
            var custId = (string?)await cmd1.ExecuteScalarAsync();
            if (string.IsNullOrEmpty(custId)) return false;

            using var cmd2 = new MySqlCommand(
                "SELECT blacklisted FROM customers WHERE customer_id=@c LIMIT 1", conn);
            cmd2.Parameters.AddWithValue("@c", custId);
            var b = await cmd2.ExecuteScalarAsync();
            var isFlag = b != null && Convert.ToBoolean(b);
            if (isFlag) return true;

            using var cmd3 = new MySqlCommand(
                "SELECT 1 FROM blacklist WHERE customer_id=@c LIMIT 1", conn);
            cmd3.Parameters.AddWithValue("@c", custId);
            var hasRow = await cmd3.ExecuteScalarAsync();

            return hasRow != null;
        }
        // Hàm kiểm tra trùng lặp client_request_id
        private async Task<bool> IsDuplicateClientReqAsync(MySqlConnection conn, string clientReqId)
        {
            using var cmd = new MySqlCommand(
                "SELECT 1 FROM transactions WHERE client_request_id=@r LIMIT 1", conn);
            cmd.Parameters.AddWithValue("@r", clientReqId);
            var v = await cmd.ExecuteScalarAsync();
            return v != null;
        }

        // ---------------------- INTERNAL ----------------------
        public async Task<TransferResponse> InternalTransferAsync(InternalTransferRequest req, string userId)
        {
            await using var conn = NewConn();
            await conn.OpenAsync();

            if (await IsSenderBlacklistedAsync(conn, req.FromAccountId))
                return TransferResponse.Fail(403, "BLACKLISTED", "Sender is blacklisted");

            if (!string.IsNullOrWhiteSpace(req.ClientRequestId) &&
                await IsDuplicateClientReqAsync(conn, req.ClientRequestId))
                return TransferResponse.Fail(409, "IDEMPOTENT_HIT", "client_request_id already used");

            using var cmd = new MySqlCommand(
                "CALL sp_transfer_internal(@tx,@from,@to,@amt,@ccy,@desc,@creq,@err,@det)", conn);

            cmd.Parameters.AddWithValue("@tx", Guid.NewGuid().ToString("N"));
            cmd.Parameters.AddWithValue("@from", req.FromAccountId);
            cmd.Parameters.AddWithValue("@to", req.ToAccountId);
            cmd.Parameters.AddWithValue("@amt", req.Amount);
            cmd.Parameters.AddWithValue("@ccy", req.Currency);
            cmd.Parameters.AddWithValue("@desc", req.Description ?? "");
            cmd.Parameters.AddWithValue("@creq", req.ClientRequestId);
            cmd.Parameters.Add(new MySqlParameter("@err", MySqlDbType.VarChar) { Direction = ParameterDirection.Output });
            cmd.Parameters.Add(new MySqlParameter("@det", MySqlDbType.VarChar) { Direction = ParameterDirection.Output });

            await cmd.ExecuteNonQueryAsync();

            var code = cmd.Parameters["@err"].Value?.ToString();
            var det = cmd.Parameters["@det"].Value?.ToString();

            _logger.LogInformation("INT xfer {From}->{To} {Amt} {Ccy} | {Code}:{Det}",
                req.FromAccountId, req.ToAccountId, req.Amount, req.Currency, code ?? "OK", det);

            return string.IsNullOrEmpty(code)
                ? TransferResponse.Ok("Internal transfer successful")
                : TransferResponse.Fail(400, code!, det);
        }

        // ---------------------- EXTERNAL REQUEST ----------------------
        public async Task<TransferResponse> ExternalTransferRequestAsync(ExternalTransferRequest req, string userId)
        {
            await using var conn = NewConn();
            await conn.OpenAsync();

            if (await IsSenderBlacklistedAsync(conn, req.FromAccountId))
                return TransferResponse.Fail(403, "BLACKLISTED", "Sender is blacklisted");

            if (!string.IsNullOrWhiteSpace(req.ClientRequestId) &&
                await IsDuplicateClientReqAsync(conn, req.ClientRequestId))
                return TransferResponse.Fail(409, "IDEMPOTENT_HIT", "client_request_id already used");

            using var cmd = new MySqlCommand(
                "CALL sp_transfer_external_request(@tx,@from,@bank,@ext_ref,@name,@amt,@ccy,@desc,@creq,@err,@det)", conn);

            cmd.Parameters.AddWithValue("@tx", Guid.NewGuid().ToString("N"));
            cmd.Parameters.AddWithValue("@from", req.FromAccountId);
            cmd.Parameters.AddWithValue("@bank", req.ToBankId);
            cmd.Parameters.AddWithValue("@ext_ref", req.ToExternalRef);
            cmd.Parameters.AddWithValue("@name", req.CounterpartyName);
            cmd.Parameters.AddWithValue("@amt", req.Amount);
            cmd.Parameters.AddWithValue("@ccy", req.Currency);
            cmd.Parameters.AddWithValue("@desc", req.Description ?? "");
            cmd.Parameters.AddWithValue("@creq", req.ClientRequestId);
            cmd.Parameters.Add(new MySqlParameter("@err", MySqlDbType.VarChar) { Direction = ParameterDirection.Output });
            cmd.Parameters.Add(new MySqlParameter("@det", MySqlDbType.VarChar) { Direction = ParameterDirection.Output });

            await cmd.ExecuteNonQueryAsync();

            var code = cmd.Parameters["@err"].Value?.ToString();
            var det = cmd.Parameters["@det"].Value?.ToString();

            _logger.LogInformation("EXT REQ {From}->[{Bank}:{Acc}] {Amt} {Ccy} | {Code}:{Det}",
                req.FromAccountId, req.ToBankId, req.ToExternalRef, req.Amount, req.Currency, code ?? "OK", det);

            return string.IsNullOrEmpty(code)
                ? TransferResponse.Ok("External transfer request successful")
                : TransferResponse.Fail(400, code!, det);
        }

        // ---------------------- EXTERNAL SETTLE ----------------------
        public async Task<TransferResponse> ExternalTransferSettleAsync(ExternalSettleRequest req, string userId)
        {
            await using var conn = NewConn();
            await conn.OpenAsync();

            using var cmd = new MySqlCommand(
                "CALL sp_transfer_external_settle(@tx,@ok,@fcode,@fdet)", conn);

            cmd.Parameters.AddWithValue("@tx", req.TransactionId);
            cmd.Parameters.AddWithValue("@ok", req.Success ? 1 : 0);
            cmd.Parameters.AddWithValue("@fcode", req.FailureCode ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("@fdet", req.FailureDetail ?? (object)DBNull.Value);

            await cmd.ExecuteNonQueryAsync();

            _logger.LogInformation("EXT SETTLE Tx={Tx} Success={Ok} Fail={Code}:{Det}",
                req.TransactionId, req.Success, req.FailureCode, req.FailureDetail);

            return TransferResponse.Ok("External transfer settled");
        }

        public async Task<TransferResponse> CheckConditionAsync(InternalTransferRequest req)
        {
            await using var conn = NewConn();
            await conn.OpenAsync();

            if (await IsSenderBlacklistedAsync(conn, req.FromAccountId))
                return TransferResponse.Ok("Sender is blacklisted", "BLACKLISTED", false);

            if (!string.IsNullOrWhiteSpace(req.ClientRequestId) &&
                await IsDuplicateClientReqAsync(conn, req.ClientRequestId))
                return TransferResponse.Ok("Client request ID already used", "IDEMPOTENT_HIT", false);

            using var cmd = new MySqlCommand("SELECT balance FROM accounts WHERE account_id=@acc", conn);
            cmd.Parameters.AddWithValue("@acc", req.FromAccountId);
            var bal = Convert.ToDecimal(await cmd.ExecuteScalarAsync() ?? 0);
            if (bal < req.Amount)
                return TransferResponse.Ok("Not enough balance", "INSUFFICIENT_FUNDS", false);

            return TransferResponse.Ok("All checks passed", null, true);
        }

        public static TransferResponse Ok(string message, string? code, bool success)
        {
            return new TransferResponse
            {
                StatusCode = 200,
                Success = success,
                Code = code,
                Message = message
            };
        }


        // Hàm xác minh mã PIN từ user-service
        public async Task<bool> VerifyPinViaUserServiceAsync(string ownerType, string ownerId, string pin)
        {
            var url = "http://user-service:8080/api/customers/verify-pin";
            var token = _httpContextAccessor.HttpContext?.Request.Headers["Authorization"].FirstOrDefault();

            var payload = new
            {
                ownerType = "account",
                ownerId = ownerId,
                pin = pin
            };

            var request = new HttpRequestMessage(HttpMethod.Post, url)
            {
                Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
            };

            if (!string.IsNullOrEmpty(token))
            {
                request.Headers.Add("Authorization", token);
            }

            var response = await _http.SendAsync(request);
            if (!response.IsSuccessStatusCode)
                return false;

            var json = await response.Content.ReadAsStringAsync();
            using var document = JsonDocument.Parse(json);

            // Đọc đúng key "valid" thay vì "success"
            if (document.RootElement.TryGetProperty("valid", out var validElement) && validElement.GetBoolean())
                return true;

            return false;
        }

        public string GenerateOtp(string accountId)
        {
            var otp = new Random().Next(100000, 999999).ToString();
            var key = $"otp:{accountId}";

            _redis.StringSet(key, otp, TimeSpan.FromMinutes(5)); // TTL 5 phút
            _logger.LogInformation($"OTP for {accountId}: {otp}");

            return otp;
        }

        public bool VerifyOtp(string accountId, string code)
        {
            var key = $"otp:{accountId}";
            var storedOtp = _redis.StringGet(key);

            if (storedOtp.IsNullOrEmpty) return false;

            if (storedOtp == code)
            {
                _redis.KeyDelete(key); // OTP dùng 1 lần
                return true;
            }

            return false;
        }
       public string? PeekOtp(string accountId)
        {
            var key = $"otp:{accountId}";
            var value = _redis.StringGet(key);
            _logger.LogInformation("[OTP DEBUG] PeekOtp key = {key}, value = {value}", key, value);
            return value;
        }
    }
}
