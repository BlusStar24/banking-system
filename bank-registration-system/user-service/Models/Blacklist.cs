using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace user_service.Models
{
    [Table("blacklist")]
    public class Blacklist
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("customer_id")]
        public string CustomerId { get; set; }

        [Column("reason")]
        public string? Reason { get; set; }

        [Column("blacklisted_at")]
        public DateTime BlacklistedAt { get; set; } = DateTime.UtcNow;
    }
}
