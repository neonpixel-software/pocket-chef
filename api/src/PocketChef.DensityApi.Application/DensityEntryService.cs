using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application;

public sealed class DensityEntryService : IDensityEntryService
{
    private readonly IDensityEntryRepository _repository;

    public DensityEntryService(IDensityEntryRepository repository)
    {
        _repository = repository;
    }

    public Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken)
        => _repository.GetAllAsync(cancellationToken);

    public async Task<DensityEntry> UpsertAsync(string ingredientName, double gramsPerCup, CancellationToken cancellationToken)
    {
        var existing = await _repository.FindByNameAsync(ingredientName, cancellationToken);
        var entry = new DensityEntry(existing?.Id ?? Guid.NewGuid(), ingredientName, gramsPerCup);
        return await _repository.UpsertAsync(entry, cancellationToken);
    }
}
