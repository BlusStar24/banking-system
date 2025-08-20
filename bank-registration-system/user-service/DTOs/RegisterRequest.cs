using System.ComponentModel.DataAnnotations;

namespace user_service.DTOs
{
    public class RegisterRequest
    {
        [Required]
        public string Name { get; set; }

        [Required]
        public string Phone { get; set; }

        [Required]
        public string CCCD { get; set; }

        public DateTime? Dob { get; set; }

        public string? Hometown { get; set; }

        [EmailAddress]
        public string? Email { get; set; }

        [Required]
        public string Method { get; set; } = "email";// email hoặc sms

        [Required]
        public string Gender { get; set; }

    }
}
