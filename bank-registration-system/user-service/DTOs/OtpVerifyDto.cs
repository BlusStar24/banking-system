using System.ComponentModel.DataAnnotations;

namespace user_service.DTOs
{
    public class OtpVerifyDto
    {
        [Required]
        public string Phone { get; set; }

        [Required]
        public string Code { get; set; }

        public string SessionId { get; set; }
        public string CsrfToken { get; set; }
    }
}
