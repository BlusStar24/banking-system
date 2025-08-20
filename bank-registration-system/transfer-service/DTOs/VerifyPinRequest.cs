public class VerifyPinRequest
{
    public string OwnerType { get; set; } = "account";
    public string OwnerId { get; set; } = string.Empty;
    public string Pin { get; set; } = string.Empty;
}
