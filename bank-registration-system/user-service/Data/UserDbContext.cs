using Microsoft.EntityFrameworkCore;
using user_service.Models;

namespace user_service.Data
{
    public class UserDbContext : DbContext
    {
        public UserDbContext(DbContextOptions<UserDbContext> options) : base(options) { }

        // Bảng login user (liên kết với Customers)
        public DbSet<User> Users { get; set; }

        // Bảng khách hàng (CIF)
        public DbSet<Customer> Customers { get; set; }

        // Bảng tài khoản ngân hàng
        public DbSet<Account> Accounts { get; set; }

        // Bảng giao dịch
        public DbSet<Transaction> Transactions { get; set; }

        // Bảng yêu cầu giao dịch (OTP)
        public DbSet<TransactionRequest> TransactionRequests { get; set; }

        // Bảng OTP request (cho đăng ký, xác thực)
        public DbSet<OtpRequest> OtpRequests { get; set; }

        // Bảng blacklist
        public DbSet<Blacklist> Blacklists { get; set; }

        // Bảng nhân viên
        public DbSet<Employee> Employees { get; set; }

        public DbSet<RefreshToken> RefreshTokens { get; set; }
        public DbSet<PinCode> PinCodes { get; set; }


    }
}
