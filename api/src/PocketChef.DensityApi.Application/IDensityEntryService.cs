using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application;

public interface IDensityEntryService
{
    public Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken);

    public Task<DensityEntry> UpsertAsync(string ingredientName, double gramsPerMilliliter, CancellationToken cancellationToken);
}
