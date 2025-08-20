namespace transfer_service.DTOs
{
    public class TransferResponse
    {
        public int StatusCode { get; set; }
        public string? Code { get; set; }
        public string? Message { get; set; }
        public bool Success { get; set; } = true;

        public static TransferResponse Ok(string message)
        {
            return new TransferResponse
            {
                StatusCode = 200,
                Success = true,
                Message = message
            };
        }

        public static TransferResponse Fail(int statusCode, string code, string message)
        {
            return new TransferResponse
            {
                StatusCode = statusCode,
                Success = false,
                Code = code,
                Message = message
            };
        }

        // ✅ Overload dùng riêng cho CheckConditionAsync
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
    }
}
