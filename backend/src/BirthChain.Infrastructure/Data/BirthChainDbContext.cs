using BirthChain.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace BirthChain.Infrastructure.Data;

public class BirthChainDbContext : DbContext
{
    public BirthChainDbContext(DbContextOptions<BirthChainDbContext> options)
        : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Provider> Providers => Set<Provider>();
    public DbSet<Client> Clients => Set<Client>();
    public DbSet<Record> Records => Set<Record>();
    public DbSet<ActivityLog> ActivityLogs => Set<ActivityLog>();
    public DbSet<Facility> Facilities => Set<Facility>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<Notification> Notifications => Set<Notification>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ── User ──
        modelBuilder.Entity<User>(e =>
        {
            e.HasKey(u => u.Id);
            e.Property(u => u.FullName).IsRequired().HasMaxLength(200);
            e.Property(u => u.Email).IsRequired().HasMaxLength(200);
            e.HasIndex(u => u.Email).IsUnique();
            e.Property(u => u.PasswordHash).IsRequired();
            e.Property(u => u.Role).IsRequired().HasMaxLength(50);

            // Optional link to a Facility (for FacilityAdmin users)
            e.HasOne<Facility>()
             .WithMany()
             .HasForeignKey(u => u.FacilityId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── Facility ──
        modelBuilder.Entity<Facility>(e =>
        {
            e.HasKey(f => f.Id);
            e.Property(f => f.Name).IsRequired().HasMaxLength(300);
            e.HasIndex(f => f.Name).IsUnique();
            e.Property(f => f.Address).HasMaxLength(500);
            e.Property(f => f.Phone).HasMaxLength(50);
            e.Property(f => f.Email).HasMaxLength(200);
        });

        // ── Provider (profile → User, → Facility) ──
        modelBuilder.Entity<Provider>(e =>
        {
            e.HasKey(p => p.Id);
            e.Property(p => p.LicenseNumber).IsRequired().HasMaxLength(100);
            e.Property(p => p.Specialty).IsRequired().HasMaxLength(200);
            e.HasIndex(p => p.UserId).IsUnique();

            e.HasOne<User>()
             .WithOne()
             .HasForeignKey<Provider>(p => p.UserId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne<Facility>()
             .WithMany()
             .HasForeignKey(p => p.FacilityId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Client ──
        modelBuilder.Entity<Client>(e =>
        {
            e.HasKey(c => c.Id);
            e.Property(c => c.FullName).IsRequired().HasMaxLength(200);
            e.Property(c => c.Phone).HasMaxLength(50);
            e.Property(c => c.QrCodeId).IsRequired().HasMaxLength(100);
            e.HasIndex(c => c.QrCodeId).IsUnique();

            // Optional link to a User account (for self-registered patients)
            e.HasIndex(c => c.UserId).IsUnique().HasFilter("\"UserId\" IS NOT NULL");
            e.HasOne<User>()
             .WithOne()
             .HasForeignKey<Client>(c => c.UserId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── Record ──
        modelBuilder.Entity<Record>(e =>
        {
            e.HasKey(r => r.Id);
            e.Property(r => r.Description).IsRequired().HasMaxLength(2000);
            e.HasIndex(r => r.ClientId);
            e.HasIndex(r => r.ProviderId);

            e.HasOne<Client>()
             .WithMany()
             .HasForeignKey(r => r.ClientId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne<Provider>()
             .WithMany()
             .HasForeignKey(r => r.ProviderId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── OtpCode ──
        modelBuilder.Entity<OtpCode>(e =>
        {
            e.HasKey(o => o.Id);
            e.Property(o => o.Email).IsRequired().HasMaxLength(200);
            e.Property(o => o.Code).IsRequired().HasMaxLength(10);
            e.Property(o => o.Purpose).IsRequired().HasMaxLength(50);
            e.HasIndex(o => new { o.Email, o.Purpose });
        });

        // ── ActivityLog ──
        modelBuilder.Entity<ActivityLog>(e =>
        {
            e.HasKey(a => a.Id);
            e.Property(a => a.Action).IsRequired().HasMaxLength(500);
            e.HasIndex(a => a.UserId);
            e.HasIndex(a => a.Timestamp);

            e.HasOne<User>()
             .WithMany()
             .HasForeignKey(a => a.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Notification ──
        modelBuilder.Entity<Notification>(e =>
        {
            e.HasKey(n => n.Id);
            e.Property(n => n.Title).IsRequired().HasMaxLength(200);
            e.Property(n => n.Body).HasMaxLength(1000);
            e.HasIndex(n => n.UserId);
            e.HasIndex(n => n.CreatedAt);

            e.HasOne<User>()
             .WithMany()
             .HasForeignKey(n => n.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
