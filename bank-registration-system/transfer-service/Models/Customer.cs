using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace transfer_service.Models
{
    [Table("customers")]
    public class Customer
    {
        [Key]
        [Column("customer_id")]
        public string CustomerId { get; set; }

        [Column("name")]
        public string Name { get; set; }

        [Column("blacklisted")]
        public bool Blacklisted { get; set; }
    }
}
