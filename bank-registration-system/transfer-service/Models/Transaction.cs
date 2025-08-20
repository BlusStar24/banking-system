using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace transfer_service.Models
{
    [Table("transactions")]
    public class Transaction
    {
        [Key]
        [Column("transaction_id")]
        public string TransactionId { get; set; }

        public string FromAccountId { get; set; }
        public string ToInternalAccountId { get; set; }
        public string ToExternalRef { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; }
        public string Description { get; set; }
        public string Status { get; set; }
        public string Type { get; set; }
    }
}
