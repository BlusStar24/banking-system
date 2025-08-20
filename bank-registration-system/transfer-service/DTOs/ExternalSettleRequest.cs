namespace transfer_service.DTOs
{
    public class ExternalSettleRequest
    {
        public string TransactionId { get; set; } = default!;
        public bool Success { get; set; }
        public string? FailureCode { get; set; }
        public string? FailureDetail { get; set; }
    }
}
