using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace transfer_service.Models
{
    [Table("accounts")]
    public class Account
    {
        [Key]
        [Column("account_id")]
        public string AccountId { get; set; }

        [Column("customer_id")]
        public string CustomerId { get; set; }

        [Column("balance")]
        public decimal Balance { get; set; }

        [Column("currency")]
        public string Currency { get; set; }

        [Column("status")]
        public string Status { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        public Customer Customer { get; set; }
    }
}
