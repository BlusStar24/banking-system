namespace user_service.DTOs
{
    public class SetPinRequest
    {
        public string OwnerType { get; set; } = default!; // "user", "account", "card"
        public string OwnerId { get; set; } = default!;
        public string Pin { get; set; } = default!;
    }

    public class VerifyPinRequest
    {
        public string OwnerType { get; set; } = default!;
        public string OwnerId { get; set; } = default!;
        public string Pin { get; set; } = default!;
    }
}
