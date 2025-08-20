using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace user_service.Models
{
    [Table("accounts")]
    public class Account
    {
        [Key]
        [Column("account_id")]
        public string AccountId { get; set; } = Guid.NewGuid().ToString();

        [ForeignKey("CustomerId")]
        [Column("customer_id")]
        public string CustomerId { get; set; }

        [Column("type")]
        public string? Type { get; set; }

        [Column("label")]
        public string? Label { get; set; }

        [Column("balance")]
        public decimal Balance { get; set; } = 0;

        [Column("currency")]
        public string Currency { get; set; } = "VND";

        [Column("bank_code")]
        public string? BankCode { get; set; }
        [Column("account_number")]
        public string AccountNumber { get; set; }

        [Column("status")]
        public string Status { get; set; } = "active";

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
