namespace transfer_service.DTOs
{
    public class InternalTransferRequest
    {
        public string FromAccountId { get; set; } = default!;
        public string ToAccountId { get; set; } = default!;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "VND";
        public string? Description { get; set; }
        public string ClientRequestId { get; set; } = default!;
    }
}
