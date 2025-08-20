namespace user_service.DTOs
{
    public class CustomerDto
    {
        public string CustomerId { get; set; }
        public string Name { get; set; }
        public string CCCD { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public DateTime Dob { get; set; }
        public string Hometown { get; set; }
        public string Status { get; set; }
        public string? Cif { get; set; }
    }
}
