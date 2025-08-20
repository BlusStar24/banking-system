using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace transfer_service.Models
{
    [Table("blacklist")]
    public class Blacklist
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("customer_id")]
        public string CustomerId { get; set; }
    }
}
