using System.ComponentModel.DataAnnotations;

namespace user_service.DTOs
{
    public class CreateUserDto
    {
        [Required]
        public string Username { get; set; }

        [Required]
        public string PasswordHash { get; set; }

        public string Role { get; set; } = "customer";

        public string? LinkedCustomerId { get; set; }
    }
}
