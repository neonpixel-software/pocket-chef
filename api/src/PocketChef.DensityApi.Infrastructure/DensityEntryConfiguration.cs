using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Infrastructure;

public sealed class DensityEntryConfiguration : IEntityTypeConfiguration<DensityEntry>
{
    // Named explicitly (matches what EF's naming convention already produces, so this doesn't
    // change the schema) so DensityEntryRepository can scope its unique-violation handling to
    // this specific index by name, rather than treating any 23505 as a name conflict.
    public const string IngredientNameUniqueIndexName = "IX_density_entries_IngredientName";

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
            .IsUnique()
            .HasDatabaseName(IngredientNameUniqueIndexName);

        builder.Property(entry => entry.GramsPerCup)
            .IsRequired();

        builder.Property(entry => entry.LastModifiedUtc)
            .IsRequired();
    }
}
