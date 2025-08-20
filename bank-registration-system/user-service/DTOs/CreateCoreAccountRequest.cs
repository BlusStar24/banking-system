namespace user_service.DTOs
{
    public class CreateCoreAccountRequest
    {
        // Liên kết với customer_id trong bảng customers
        public string CustomerId { get; set; }

        // Loại tài khoản: SAVING (tiết kiệm) hoặc CURRENT (thanh toán)
        public string AccountType { get; set; } = "SAVING";

        // Số dư ban đầu
        public decimal InitialBalance { get; set; } = 0;

        // 2 trường hợp tạo số cho tài khoản 
         public string? AccountNumber { get; set; }
    }
}
