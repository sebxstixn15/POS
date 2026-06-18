using Microsoft.EntityFrameworkCore;
using Waldwunderverwaltung.Models;

namespace Waldwunderverwaltung
{
    public class AppDbContext : DbContext
    {
        public DbSet<Waldwunder> Waldwunders { get; set; }
        public DbSet<Bilder> Bilders { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder options)
            => options.UseSqlite("Data Source=Waldwunder.db");

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Store the Bundesland enum as its string name (e.g. "Niederösterreich")
            // so it matches the existing TEXT column in the database.
            modelBuilder.Entity<Waldwunder>()
                .Property(w => w.Province)
                .HasConversion<string>();
        }
    }
}
