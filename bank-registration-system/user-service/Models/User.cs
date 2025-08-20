using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace user_service.Models
{
    [Table("users")]
    public class User
    {
        [Key]
        [Column("user_id")]
        public string UserId { get; set; } = Guid.NewGuid().ToString();

        [Column("username")]
        public string Username { get; set; }

        [Column("password_hash")]
        public string PasswordHash { get; set; }

        [Column("role")]
        public string Role { get; set; } = "customer";

        [Column("linked_customer_id")]
        public string? LinkedCustomerId { get; set; }
        [ForeignKey("LinkedCustomerId")]
        public Customer? LinkedCustomer { get; set; }
    }
}
