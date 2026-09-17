using PocketChef.DensityApi.Application;
using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application.Tests;

public class DensityEntryServiceTests
{
    [Fact]
    public async Task GetAllAsync_ReturnsWhateverTheRepositoryReturns()
    {
        var entries = new List<DensityEntry> { new(Guid.NewGuid(), "Flour", 120) };
        var repository = new FakeDensityEntryRepository { AllEntries = entries };
        var service = new DensityEntryService(repository);

        var result = await service.GetAllAsync(CancellationToken.None);

        Assert.Same(entries, result);
    }

    [Fact]
    public async Task UpsertAsync_CreatesANewEntryWhenNoneExistsForThatName()
    {
        var repository = new FakeDensityEntryRepository { FindByNameResult = null };
        var service = new DensityEntryService(repository);

        var result = await service.UpsertAsync("Sugar", 200, CancellationToken.None);

        Assert.Equal("Sugar", result.IngredientName);
        Assert.Equal(200, result.GramsPerCup);
        Assert.NotNull(repository.LastUpsertedEntry);
        Assert.Equal(result.Id, repository.LastUpsertedEntry!.Id);
    }

    [Fact]
    public async Task UpsertAsync_ReusesTheExistingIdWhenAnEntryAlreadyExistsForThatName()
    {
        var existing = new DensityEntry(Guid.NewGuid(), "Sugar", 190);
        var repository = new FakeDensityEntryRepository { FindByNameResult = existing };
        var service = new DensityEntryService(repository);

        var result = await service.UpsertAsync("Sugar", 200, CancellationToken.None);

        Assert.Equal(existing.Id, result.Id);
        Assert.Equal(200, result.GramsPerCup);
    }

    private sealed class FakeDensityEntryRepository : IDensityEntryRepository
    {
        public IReadOnlyList<DensityEntry> AllEntries { get; set; } = [];
        public DensityEntry? FindByNameResult { get; set; }
        public DensityEntry? LastUpsertedEntry { get; private set; }

        public Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken)
            => Task.FromResult(AllEntries);

        public Task<DensityEntry?> FindByNameAsync(string ingredientName, CancellationToken cancellationToken)
            => Task.FromResult(FindByNameResult);

        public Task<DensityEntry> UpsertAsync(DensityEntry entry, CancellationToken cancellationToken)
        {
            LastUpsertedEntry = entry;
            return Task.FromResult(entry);
        }
    }
}
