using PocketChef.DensityApi.Application.Seeding;
using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application.Tests;

public class DensitySeederTests
{
    private static readonly DateTimeOffset SomeLastModifiedUtc = new(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);

    private static DensitySeedRow Row(string name, double grams)
        => new(name, FdcId: 1, Amount: 1, Portion: "cup", HouseholdMeasure.Cup, grams);

    [Fact]
    public async Task SeedAsync_InsertsEveryRowIntoAnEmptyTable()
    {
        var repository = new FakeDensityEntryRepository();
        var seeder = new DensitySeeder(repository);
        var before = DateTimeOffset.UtcNow;

        var result = await seeder.SeedAsync([Row("flour", 125), Row("sugar", 200)], CancellationToken.None);

        Assert.Equal(["flour", "sugar"], result.Inserted.Select(entry => entry.IngredientName));
        Assert.Empty(result.Skipped);
        var stored = await repository.GetAllAsync(CancellationToken.None);
        Assert.Equal(2, stored.Count);
        Assert.Equal(125 / HouseholdMeasures.CupMilliliters, stored[0].GramsPerMilliliter);
        Assert.All(stored, entry => Assert.InRange(entry.LastModifiedUtc, before, DateTimeOffset.UtcNow));
    }

    [Fact]
    public async Task SeedAsync_LeavesAnExistingEntryUntouchedEvenWhenTheSeedValueDiffers()
    {
        // A hand-curated value (or a case variant of the seed name) must survive a re-run,
        // including its LastModifiedUtc, which clients use to fetch only what changed.
        var curated = new DensityEntry(Guid.NewGuid(), "Flour", 0.6, SomeLastModifiedUtc);
        var repository = new FakeDensityEntryRepository(curated);
        var seeder = new DensitySeeder(repository);

        var result = await seeder.SeedAsync([Row("flour", 125)], CancellationToken.None);

        Assert.Empty(result.Inserted);
        var skipped = Assert.Single(result.Skipped);
        Assert.Same(curated, skipped.Existing);
        Assert.Equal("flour", skipped.Row.IngredientName);
        Assert.Same(curated, Assert.Single(await repository.GetAllAsync(CancellationToken.None)));
    }

    [Fact]
    public async Task SeedAsync_IsANoOpTheSecondTime()
    {
        var repository = new FakeDensityEntryRepository();
        var seeder = new DensitySeeder(repository);
        DensitySeedRow[] rows = [Row("flour", 125), Row("sugar", 200)];
        await seeder.SeedAsync(rows, CancellationToken.None);

        var second = await seeder.SeedAsync(rows, CancellationToken.None);

        Assert.Empty(second.Inserted);
        Assert.Equal(2, second.Skipped.Count);
        Assert.Equal(2, (await repository.GetAllAsync(CancellationToken.None)).Count);
    }

    [Fact]
    public async Task SeedAsync_MatchesAnExistingEntryAfterCanonicalizingTheSeedName()
    {
        // Issue #55: without canonicalizing first, a padded or decomposed seed name misses
        // the stored row and the insert then hits the unique index.
        var existing = new DensityEntry(Guid.NewGuid(), "crème fraîche", 1.0, SomeLastModifiedUtc);
        var repository = new FakeDensityEntryRepository(existing);
        var seeder = new DensitySeeder(repository);
        var decomposedAndPadded = " crème fraîche ";

        var result = await seeder.SeedAsync([Row(decomposedAndPadded, 240)], CancellationToken.None);

        Assert.Empty(result.Inserted);
        Assert.Same(existing, Assert.Single(result.Skipped).Existing);
    }

    [Fact]
    public async Task SeedAsync_StoresTheCanonicalName()
    {
        var repository = new FakeDensityEntryRepository();
        var seeder = new DensitySeeder(repository);

        await seeder.SeedAsync([Row(" crème fraîche ", 240)], CancellationToken.None);

        var stored = Assert.Single(await repository.GetAllAsync(CancellationToken.None));
        Assert.Equal("crème fraîche", stored.IngredientName);
    }
}
