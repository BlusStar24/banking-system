namespace user_service.DTOs
{
    public class ChangePasswordRequest
    {
        public string CustomerId { get; set; }
        public string OldPassword { get; set; }
        public string NewPassword { get; set; }
    }
}
