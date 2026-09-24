using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application.Tests;

public class DensityEntryServiceTests
{
    private static readonly DateTimeOffset SomeLastModifiedUtc = new(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);

    [Fact]
    public async Task GetAllAsync_ReturnsWhateverTheRepositoryReturns()
    {
        var entries = new[] { new DensityEntry(Guid.NewGuid(), "Flour", 0.53, SomeLastModifiedUtc) };
        var repository = new FakeDensityEntryRepository(entries);
        var service = new DensityEntryService(repository);

        var result = await service.GetAllAsync(CancellationToken.None);

        Assert.Equal(entries, result);
    }

    [Fact]
    public async Task UpsertAsync_CreatesANewEntryWhenNoneExistsForThatName()
    {
        var repository = new FakeDensityEntryRepository();
        var service = new DensityEntryService(repository);
        var before = DateTimeOffset.UtcNow;

        var result = await service.UpsertAsync("Sugar", 0.85, CancellationToken.None);

        Assert.Equal("Sugar", result.IngredientName);
        Assert.Equal(0.85, result.GramsPerMilliliter);
        Assert.InRange(result.LastModifiedUtc, before, DateTimeOffset.UtcNow);
        Assert.NotNull(repository.LastUpsertedEntry);
        Assert.Equal(result.Id, repository.LastUpsertedEntry!.Id);
    }

    [Fact]
    public async Task UpsertAsync_ReusesTheExistingIdWhenAnEntryAlreadyExistsForThatName()
    {
        var existing = new DensityEntry(Guid.NewGuid(), "Sugar", 0.80, SomeLastModifiedUtc);
        var repository = new FakeDensityEntryRepository(existing);
        var service = new DensityEntryService(repository);

        var result = await service.UpsertAsync("Sugar", 0.85, CancellationToken.None);

        Assert.Equal(existing.Id, result.Id);
        Assert.Equal(0.85, result.GramsPerMilliliter);
        Assert.True(result.LastModifiedUtc > existing.LastModifiedUtc);
    }

    [Fact]
    public async Task UpsertAsync_WhitespacePaddedName_MergesWithTheExistingEntry()
    {
        // Issue #55: the database's citext index folds case but treats whitespace as
        // significant, so a trailing space slipped past the lookup and then hit the unique
        // index — a 409 conflict for a name that already exists.
        var existing = new DensityEntry(Guid.NewGuid(), "butter", 0.90, SomeLastModifiedUtc);
        var repository = new FakeDensityEntryRepository(existing);
        var service = new DensityEntryService(repository);

        var result = await service.UpsertAsync("butter ", 0.96, CancellationToken.None);

        Assert.Equal(existing.Id, result.Id);
        Assert.Equal("butter", result.IngredientName);
        Assert.Equal(0.96, result.GramsPerMilliliter);
    }

    [Fact]
    public async Task UpsertAsync_DecomposedUnicodeName_MergesWithTheComposedExistingEntry()
    {
        // Same failure mode as the whitespace case, via Unicode canonical form: a composed
        // "é" and "e" + combining accent are different byte sequences to the database, so
        // only a canonicalized lookup can find the stored entry.
        var existing = new DensityEntry(Guid.NewGuid(), "café", 0.45, SomeLastModifiedUtc);
        var repository = new FakeDensityEntryRepository(existing);
        var service = new DensityEntryService(repository);

        var result = await service.UpsertAsync("cafe\u0301", 0.53, CancellationToken.None);

        Assert.Equal(existing.Id, result.Id);
        Assert.Equal("café", result.IngredientName);
        Assert.Equal(0.53, result.GramsPerMilliliter);
    }

    [Fact]
    public async Task UpsertAsync_NullIngredientName_ThrowsArgument()
    {
        // A JSON null name binds fine to the non-nullable string parameter, so the
        // service is the first place that sees it. An unguarded Canonicalize would then
        // throw a raw NullReferenceException — a 500 where the constructor's
        // IsNullOrWhiteSpace check used to produce a clean 400.
        var repository = new FakeDensityEntryRepository();
        var service = new DensityEntryService(repository);

        await Assert.ThrowsAnyAsync<ArgumentException>(() => service.UpsertAsync(null!, 0.85, CancellationToken.None));
    }

    /// Simulates the database's handling of names rather than the service's expectations:
    /// FindByNameAsync matches the way the citext column does (case folds, but whitespace
    /// and Unicode canonical form are significant), and UpsertAsync enforces the way the
    /// unique index does (throws DensityEntryConflictException when a second row would hold
    /// a name that already exists). A fake that returned whatever the service asked for
    /// would pass both before and after the fix, hiding the bug.
    private sealed class FakeDensityEntryRepository : IDensityEntryRepository
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
        // locale-dependent, so non-ASCII case pairs could diverge (none of this test's
        // names exercise that); the properties under test, whitespace and canonical form,
        // compare unequal under it exactly as they do in Postgres.
        private static bool CitextEquals(string storedName, string candidate)
            => string.Equals(storedName, candidate, StringComparison.OrdinalIgnoreCase);
    }
}
