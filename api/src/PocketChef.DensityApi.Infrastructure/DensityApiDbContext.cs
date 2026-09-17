using Microsoft.EntityFrameworkCore;
using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Infrastructure;

public sealed class DensityApiDbContext : DbContext
{
    public DensityApiDbContext(DbContextOptions<DensityApiDbContext> options) : base(options)
    {
    }

    public DbSet<DensityEntry> DensityEntries => Set<DensityEntry>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("citext");
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(DensityApiDbContext).Assembly);
    }
}
