namespace user_service.DTOs
{
    public class CreateCoreAccountResponse
    {
        // Mã CIF (mã khách hàng trong core banking)
        public string CIF { get; set; }

        // Số tài khoản (account number)
        public string AccountNumber { get; set; }

        // Email khách hàng để gửi thông báo
        public string CustomerEmail { get; set; }

        // Số điện thoại khách hàng (nếu cần gửi SMS)
        public string CustomerPhone { get; set; }
    }
}
