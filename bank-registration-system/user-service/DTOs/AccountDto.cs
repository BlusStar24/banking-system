namespace user_service.DTOs
{
    public class AccountDto
    {
        public string AccountId { get; set; } = null!;
        public string AccountNumber { get; set; }
        public decimal Balance { get; set; }
        public string Type { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
