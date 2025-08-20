using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace user_service.Models
{
    [Table("customers")]
    public class Customer
    {
        [Key]
        [Column("customer_id")]
        public string CustomerId { get; set; } = Guid.NewGuid().ToString();

        [Column("name")]
        public string Name { get; set; }

        [Column("cif")]
        public string? Cif { get; set; }

        [Column("phone")]
        public string Phone { get; set; }

        [Column("cccd")]
        public string CCCD { get; set; }

        [Column("dob")]
        public DateTime Dob { get; set; }

        [Column("gender")]
        public string Gender { get; set; }

        [Column("hometown")]
        public string? Hometown { get; set; }

        [Column("email")]
        public string? Email { get; set; }

        [Column("kyc_status")]
        public bool KycStatus { get; set; } = false;

        [Column("status")]
        public string Status { get; set; } = "pending";

        [Column("blacklisted")]
        public bool Blacklisted { get; set; } = false;

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public ICollection<Account> Accounts { get; set; }

    }
}
