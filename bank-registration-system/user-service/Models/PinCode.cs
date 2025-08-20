using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace user_service.Models
{
    public class PinCode
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string OwnerType { get; set; } // "user", "account"

        [Required]
        public string OwnerId { get; set; }

        [Required]
        public string PinHash { get; set; }

        public int FailedAttempts { get; set; } = 0;

        public bool IsLocked { get; set; } = false;

        public DateTime LastChanged { get; set; } = DateTime.UtcNow;
    }
}
