using Microsoft.EntityFrameworkCore;
using QuizGame.Domain.Entities;

namespace QuizGame.Infrastructure.Data;

/// <summary>
/// EF Core DbContext using InMemory provider for development.
/// To switch to SQL Server, simply change the provider registration in Program.cs
/// and add the appropriate migrations — no model changes required.
/// </summary>
public class QuizGameDbContext : DbContext
{
    public QuizGameDbContext(DbContextOptions<QuizGameDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<GameRoom> GameRooms => Set<GameRoom>();
    public DbSet<Player> Players => Set<Player>();
    public DbSet<Question> Questions => Set<Question>();
    public DbSet<GameRound> GameRounds => Set<GameRound>();
    public DbSet<PlayerAnswer> PlayerAnswers => Set<PlayerAnswer>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User
        modelBuilder.Entity<User>(e =>
        {
            e.HasKey(u => u.Id);
            e.Property(u => u.Username).IsRequired().HasMaxLength(50);
            e.HasIndex(u => u.Username).IsUnique();
        });

        // GameRoom
        modelBuilder.Entity<GameRoom>(e =>
        {
            e.HasKey(r => r.Id);
            e.Property(r => r.RoomCode).IsRequired().HasMaxLength(6);
            e.HasIndex(r => r.RoomCode).IsUnique();
            // One room → many players
            e.HasMany(r => r.Players)
             .WithOne(p => p.GameRoom)
             .HasForeignKey(p => p.GameRoomId)
             .OnDelete(DeleteBehavior.Cascade);
            // One room → many rounds
            e.HasMany(r => r.Rounds)
             .WithOne()
             .HasForeignKey(r => r.GameRoomId);
        });

        // Player
        modelBuilder.Entity<Player>(e =>
        {
            e.HasKey(p => p.Id);
            // Many players → one user
            e.HasOne(p => p.User)
             .WithMany(u => u.Players)
             .HasForeignKey(p => p.UserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // Question
        modelBuilder.Entity<Question>(e =>
        {
            e.HasKey(q => q.Id);
            e.Property(q => q.Text).IsRequired().HasMaxLength(500);
            e.Property(q => q.CorrectOption).IsRequired().HasMaxLength(1);
        });

        // GameRound
        modelBuilder.Entity<GameRound>(e =>
        {
            e.HasKey(r => r.Id);
            e.HasOne(r => r.Question)
             .WithMany()
             .HasForeignKey(r => r.QuestionId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasMany(r => r.PlayerAnswers)
             .WithOne()
             .HasForeignKey(a => a.GameRoundId);
        });

        // PlayerAnswer
        modelBuilder.Entity<PlayerAnswer>(e =>
        {
            e.HasKey(a => a.Id);
        });
    }
}
