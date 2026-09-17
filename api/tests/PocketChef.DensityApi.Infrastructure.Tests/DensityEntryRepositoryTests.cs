using Microsoft.EntityFrameworkCore;
using PocketChef.DensityApi.Application;
using PocketChef.DensityApi.Domain;
using Testcontainers.PostgreSql;

namespace PocketChef.DensityApi.Infrastructure.Tests;

public class DensityEntryRepositoryTests : IAsyncLifetime
{
    private static readonly DateTimeOffset SomeLastModifiedUtc = new(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);

    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder("postgres:17")
        .Build();

    private DensityApiDbContext _context = null!;

    public async Task InitializeAsync()
    {
        await _container.StartAsync();

        var options = new DbContextOptionsBuilder<DensityApiDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;

        _context = new DensityApiDbContext(options);
        await _context.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        await _context.DisposeAsync();
        await _container.DisposeAsync();
    }

    [Fact]
    public async Task UpsertAsync_InsertsANewEntry()
    {
        var repository = new DensityEntryRepository(_context);
        var entry = new DensityEntry(Guid.NewGuid(), "Flour", 120, SomeLastModifiedUtc);

        await repository.UpsertAsync(entry, CancellationToken.None);

        var all = await repository.GetAllAsync(CancellationToken.None);
        Assert.Single(all);
        Assert.Equal("Flour", all[0].IngredientName);
        Assert.Equal(120, all[0].GramsPerCup);
    }

    [Fact]
    public async Task UpsertAsync_PersistsLastModifiedUtcAndReadsItBackAsTheSameInstant()
    {
        var repository = new DensityEntryRepository(_context);
        var entry = new DensityEntry(Guid.NewGuid(), "Cinnamon", 100, SomeLastModifiedUtc);

        await repository.UpsertAsync(entry, CancellationToken.None);

        var all = await repository.GetAllAsync(CancellationToken.None);
        var stored = Assert.Single(all);
        // Postgres's timestamptz normalizes to UTC internally and Npgsql reads it back with a
        // UTC offset regardless of what was written — compare the instant, not the raw Offset.
        Assert.Equal(SomeLastModifiedUtc.ToUniversalTime(), stored.LastModifiedUtc.ToUniversalTime());
    }

    [Fact]
    public async Task UpsertAsync_UpdatesAnExistingEntryInPlaceRatherThanDuplicating()
    {
        var repository = new DensityEntryRepository(_context);
        var original = new DensityEntry(Guid.NewGuid(), "Sugar", 190, SomeLastModifiedUtc);
        await repository.UpsertAsync(original, CancellationToken.None);

        var newerLastModifiedUtc = SomeLastModifiedUtc.AddMinutes(5);
        var updated = new DensityEntry(original.Id, "Sugar", 200, newerLastModifiedUtc);
        await repository.UpsertAsync(updated, CancellationToken.None);

        var all = await repository.GetAllAsync(CancellationToken.None);
        var stored = Assert.Single(all);
        Assert.Equal(200, stored.GramsPerCup);
        Assert.Equal(newerLastModifiedUtc.ToUniversalTime(), stored.LastModifiedUtc.ToUniversalTime());
    }

    [Fact]
    public async Task FindByNameAsync_IsCaseInsensitive()
    {
        var repository = new DensityEntryRepository(_context);
        await repository.UpsertAsync(new DensityEntry(Guid.NewGuid(), "Butter", 227, SomeLastModifiedUtc), CancellationToken.None);

        var found = await repository.FindByNameAsync("BUTTER", CancellationToken.None);

        Assert.NotNull(found);
        Assert.Equal("Butter", found!.IngredientName);
    }

    [Fact]
    public async Task FindByNameAsync_ReturnsNullWhenNoMatch()
    {
        var repository = new DensityEntryRepository(_context);

        var found = await repository.FindByNameAsync("Nonexistent", CancellationToken.None);

        Assert.Null(found);
    }

    [Fact]
    public async Task IngredientName_UniqueConstraintIsEnforcedAtTheDatabaseLevel()
    {
        var repository = new DensityEntryRepository(_context);
        await repository.UpsertAsync(new DensityEntry(Guid.NewGuid(), "Honey", 340, SomeLastModifiedUtc), CancellationToken.None);

        // A second, distinct entry with the same (case-insensitive) name bypasses the
        // Application-layer upsert logic entirely, to prove the database itself — not just
        // the service — refuses the duplicate. The repository translates the raw
        // DbUpdateException into DensityEntryConflictException so callers above it never need
        // to know this is backed by Postgres.
        var duplicate = new DensityEntry(Guid.NewGuid(), "HONEY", 300, SomeLastModifiedUtc);

        await Assert.ThrowsAsync<DensityEntryConflictException>(async () =>
        {
            await repository.UpsertAsync(duplicate, CancellationToken.None);
        });
    }

    [Fact]
    public async Task UpsertAsync_TrueConcurrentInsertsForCaseVariantNames_ExactlyOneThrowsConflictException()
    {
        // Two independent connections/DbContexts (unlike the sequential test above) racing via
        // Task.WhenAll, so this is a genuine concurrent write, not a simulated one — Postgres's
        // unique index guarantees exactly one commits regardless of which "wins". This only
        // proves the conflict path if B's FindByNameAsync actually runs before A's insert
        // commits; if the two tasks fully serialize under CI load, both take the update path
        // and this flakes on the `Assert.Single(outcomes, outcome => !outcome)` line below. The
        // 23505 -> DensityEntryConflictException translation is already proven deterministically
        // by the sequential test above, so if this ever flakes, look here first before
        // suspecting the translation logic itself.
        var options = new DbContextOptionsBuilder<DensityApiDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;
        await using var contextA = new DensityApiDbContext(options);
        await using var contextB = new DensityApiDbContext(options);
        var repositoryA = new DensityEntryRepository(contextA);
        var repositoryB = new DensityEntryRepository(contextB);

        var entryA = new DensityEntry(Guid.NewGuid(), "Cocoa", 90, SomeLastModifiedUtc);
        var entryB = new DensityEntry(Guid.NewGuid(), "COCOA", 95, SomeLastModifiedUtc);

        var outcomes = await Task.WhenAll(
            UpsertAndReportOutcome(repositoryA, entryA),
            UpsertAndReportOutcome(repositoryB, entryB));

        Assert.Single(outcomes, outcome => outcome);
        Assert.Single(outcomes, outcome => !outcome);

        var all = await repositoryA.GetAllAsync(CancellationToken.None);
        Assert.Single(all);

        static async Task<bool> UpsertAndReportOutcome(DensityEntryRepository repository, DensityEntry entry)
        {
            try
            {
                await repository.UpsertAsync(entry, CancellationToken.None);
                return true;
            }
            catch (DensityEntryConflictException)
            {
                return false;
            }
        }
    }
}
