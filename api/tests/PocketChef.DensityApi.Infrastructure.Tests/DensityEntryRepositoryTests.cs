using Microsoft.EntityFrameworkCore;
using PocketChef.DensityApi.Domain;
using Testcontainers.PostgreSql;

namespace PocketChef.DensityApi.Infrastructure.Tests;

public class DensityEntryRepositoryTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder()
        .WithImage("postgres:17")
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
        var entry = new DensityEntry(Guid.NewGuid(), "Flour", 120);

        await repository.UpsertAsync(entry, CancellationToken.None);

        var all = await repository.GetAllAsync(CancellationToken.None);
        Assert.Single(all);
        Assert.Equal("Flour", all[0].IngredientName);
        Assert.Equal(120, all[0].GramsPerCup);
    }

    [Fact]
    public async Task UpsertAsync_UpdatesAnExistingEntryInPlaceRatherThanDuplicating()
    {
        var repository = new DensityEntryRepository(_context);
        var original = new DensityEntry(Guid.NewGuid(), "Sugar", 190);
        await repository.UpsertAsync(original, CancellationToken.None);

        var updated = new DensityEntry(original.Id, "Sugar", 200);
        await repository.UpsertAsync(updated, CancellationToken.None);

        var all = await repository.GetAllAsync(CancellationToken.None);
        Assert.Single(all);
        Assert.Equal(200, all[0].GramsPerCup);
    }

    [Fact]
    public async Task FindByNameAsync_IsCaseInsensitive()
    {
        var repository = new DensityEntryRepository(_context);
        await repository.UpsertAsync(new DensityEntry(Guid.NewGuid(), "Butter", 227), CancellationToken.None);

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
        await repository.UpsertAsync(new DensityEntry(Guid.NewGuid(), "Honey", 340), CancellationToken.None);

        // A second, distinct entry with the same (case-insensitive) name bypasses the
        // Application-layer upsert logic entirely, to prove the database itself — not just
        // the service — refuses the duplicate.
        var duplicate = new DensityEntry(Guid.NewGuid(), "HONEY", 300);

        await Assert.ThrowsAsync<DbUpdateException>(async () =>
        {
            await repository.UpsertAsync(duplicate, CancellationToken.None);
        });
    }
}
