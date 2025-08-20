using Microsoft.EntityFrameworkCore;
using transfer_service.Models;

namespace transfer_service.Data
{
    public class TransferDbContext : DbContext
    {
        public TransferDbContext(DbContextOptions<TransferDbContext> options) : base(options) { }

        public DbSet<Account> Accounts { get; set; }
        public DbSet<Customer> Customers { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<LedgerEntry> LedgerEntries { get; set; }
        public DbSet<Refund> Refunds { get; set; }
        public DbSet<Blacklist> Blacklist { get; set; }
    }
}
