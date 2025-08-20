namespace user_service.DTOs
{
    public class UserProfileDto
    {
        public string Username { get; set; }
        public string Role { get; set; }
        public string LinkedCustomerId { get; set; }
        public CustomerDto Customer { get; set; }
        public AccountDto Account { get; set; }
    }
}
