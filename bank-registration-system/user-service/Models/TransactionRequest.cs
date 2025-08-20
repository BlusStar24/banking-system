using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace user_service.Models
{
    [Table("transaction_requests")]
    public class TransactionRequest
    {
        [Key]
        [Column("request_id")]
        public string RequestId { get; set; } = Guid.NewGuid().ToString();

        [Column("from_account_id")]
        public string FromAccountId { get; set; }

        [Column("to_account_id")]
        public string ToAccountId { get; set; }

        [Column("amount")]
        public decimal Amount { get; set; }

        [Column("currency")]
        public string Currency { get; set; } = "VND";

        [Column("description")]
        public string? Description { get; set; }

        [Column("otp_code")]
        public string? OtpCode { get; set; }

        [Column("otp_verified")]
        public bool OtpVerified { get; set; } = false;

        [Column("status")]
        public string Status { get; set; } = "initiated";

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
