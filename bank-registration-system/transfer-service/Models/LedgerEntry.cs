using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace transfer_service.Models
{
    [Table("ledger_entries")]
    public class LedgerEntry
    {
        [Key]
        [Column("entry_id")]
        public string EntryId { get; set; }

        public string TransactionId { get; set; }
        public string AccountId { get; set; }
        public string Direction { get; set; }
        public decimal Amount { get; set; }
    }
}
