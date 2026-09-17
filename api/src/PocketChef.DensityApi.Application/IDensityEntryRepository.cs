using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application;

public interface IDensityEntryRepository
{
    Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken);

    Task<DensityEntry?> FindByNameAsync(string ingredientName, CancellationToken cancellationToken);

    Task<DensityEntry> UpsertAsync(DensityEntry entry, CancellationToken cancellationToken);
}
