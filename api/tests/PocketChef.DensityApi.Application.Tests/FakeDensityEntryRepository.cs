using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application.Tests;

/// Simulates the database's handling of names rather than the service's expectations:
/// FindByNameAsync matches the way the citext column does (case folds, but whitespace
/// and Unicode canonical form are significant), and UpsertAsync enforces the way the
/// unique index does (throws DensityEntryConflictException when a second row would hold
/// a name that already exists). A fake that returned whatever the service asked for
/// would pass both before and after the fix, hiding the bug.
internal sealed class FakeDensityEntryRepository : IDensityEntryRepository
{
    private readonly List<DensityEntry> _entries = [];
    public DensityEntry? LastUpsertedEntry { get; private set; }

    public FakeDensityEntryRepository(params DensityEntry[] entries)
    {
        _entries.AddRange(entries);
    }

    public Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken)
        => Task.FromResult<IReadOnlyList<DensityEntry>>(_entries);

    public Task<DensityEntry?> FindByNameAsync(string ingredientName, CancellationToken cancellationToken)
        => Task.FromResult(_entries.FirstOrDefault(entry => CitextEquals(entry.IngredientName, ingredientName)));

    public Task<DensityEntry> UpsertAsync(DensityEntry entry, CancellationToken cancellationToken)
    {
        // Postgres's unique citext index fires on INSERT and UPDATE alike: an update
        // that would end up holding a name another row already has (case-insensitive)
        // is rejected, not just a duplicate insert.
        var collides = _entries.Any(existing =>
            existing.Id != entry.Id && CitextEquals(existing.IngredientName, entry.IngredientName));
        if (collides)
        {
            throw new DensityEntryConflictException(entry.IngredientName);
        }

        var index = _entries.FindIndex(existing => existing.Id == entry.Id);
        if (index is -1)
        {
            _entries.Add(entry);
        }
        else
        {
            _entries[index] = entry;
        }

        LastUpsertedEntry = entry;
        return Task.FromResult(entry);
    }

    // citext folds case but treats whitespace and Unicode canonical form as significant.
    // OrdinalIgnoreCase approximates the case folding — Postgres's actual folding is
    // locale-dependent, so non-ASCII case pairs could diverge (none of the tests'
    // names exercise that); the properties under test, whitespace and canonical form,
    // compare unequal under it exactly as they do in Postgres.
    private static bool CitextEquals(string storedName, string candidate)
        => string.Equals(storedName, candidate, StringComparison.OrdinalIgnoreCase);
}
