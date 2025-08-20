using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace user_service.Models
{
    [Table("employee")]
    public class Employee
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Column("name")]
        public string Name { get; set; }

        [Column("email")]
        public string Email { get; set; }

        [Column("position")]
        public string? Position { get; set; }

        [Column("hired_date")]
        public DateTime? HiredDate { get; set; }

        [Column("active")]
        public bool Active { get; set; } = true;
    }
}
