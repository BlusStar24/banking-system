namespace transfer_service.DTOs
{
    public class ExternalTransferRequest
    {
        public string FromAccountId { get; set; } = default!;
        public string ToBankId { get; set; } = default!;   // ví dụ: "VCB"
        public string ToExternalRef { get; set; } = default!;   // số TK/thẻ
        public string? CounterpartyName { get; set; }               // tên người nhận (nếu có)
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "VND";
        public string? Description { get; set; }
        public string ClientRequestId { get; set; } = default!;
    }
}
