using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace transfer_service.Models
{
    [Table("refunds")]
    public class Refund
    {
        [Key]
        [Column("refund_id")]
        public string RefundId { get; set; }

        public string TransactionId { get; set; }
        public string Reason { get; set; }
        public decimal Amount { get; set; }
    }
}
