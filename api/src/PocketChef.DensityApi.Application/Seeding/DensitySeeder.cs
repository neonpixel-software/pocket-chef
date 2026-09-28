using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application.Seeding;

public sealed record SkippedDensitySeedRow(DensitySeedRow Row, DensityEntry Existing);

/// With a dry run, <see cref="Inserted"/> holds the entries that would have been inserted.
public sealed record DensitySeedResult(IReadOnlyList<DensityEntry> Inserted, IReadOnlyList<SkippedDensitySeedRow> Skipped);

/// Loads seed rows into the density table, inserting only ingredients it doesn't have yet.
///
/// An ingredient that already exists is left alone, even when its value differs from the
/// seed: after the first run, values are curated by hand through the write endpoint, and a
/// re-run must not overwrite that. Leaving existing rows alone also keeps their
/// LastModifiedUtc, so a re-run doesn't make every client re-download the whole table.
///
/// A dry run does the same lookups but writes nothing, so the rows can be checked against a
/// live table before the first real run.
public sealed class DensitySeeder
{
    private readonly IDensityEntryRepository _repository;

    public DensitySeeder(IDensityEntryRepository repository)
    {
        _repository = repository;
    }

    public async Task<DensitySeedResult> SeedAsync(IEnumerable<DensitySeedRow> rows, bool dryRun, CancellationToken cancellationToken)
    {
        var inserted = new List<DensityEntry>();
        var skipped = new List<SkippedDensitySeedRow>();

        foreach (var row in rows)
        {
            // Canonicalize before the lookup for the same reason the upsert service does
            // (issue #55): the citext index only folds case.
            var name = IngredientNames.Canonicalize(row.IngredientName);
            var existing = await _repository.FindByNameAsync(name, cancellationToken);
            if (existing is not null)
            {
                skipped.Add(new SkippedDensitySeedRow(row, existing));
                continue;
            }

            var entry = new DensityEntry(Guid.NewGuid(), name, row.GramsPerMilliliter, DateTimeOffset.UtcNow);
            inserted.Add(dryRun ? entry : await _repository.UpsertAsync(entry, cancellationToken));
        }

        return new DensitySeedResult(inserted, skipped);
    }
}
