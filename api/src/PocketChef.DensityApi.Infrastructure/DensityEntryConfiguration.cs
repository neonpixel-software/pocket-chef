using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Infrastructure;

public sealed class DensityEntryConfiguration : IEntityTypeConfiguration<DensityEntry>
{
    public void Configure(EntityTypeBuilder<DensityEntry> builder)
    {
        builder.ToTable("density_entries");

        builder.HasKey(entry => entry.Id);

        builder.Property(entry => entry.IngredientName)
            .HasColumnType("citext")
            .IsRequired();

        // citext makes this comparison (and the index) case-insensitive at the database level —
        // mirrors the Swift app's case-insensitive tag-name matching.
        builder.HasIndex(entry => entry.IngredientName)
            .IsUnique();

        builder.Property(entry => entry.GramsPerCup)
            .IsRequired();
    }
}
