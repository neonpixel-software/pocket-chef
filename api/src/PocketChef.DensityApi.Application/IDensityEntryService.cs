using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application;

public interface IDensityEntryService
{
    Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken);

    Task<DensityEntry> UpsertAsync(string ingredientName, double gramsPerCup, CancellationToken cancellationToken);
}
