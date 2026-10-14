using RecipeRaccoon.DensityApi.Domain;

namespace RecipeRaccoon.DensityApi.Application;

public interface IDensityEntryRepository
{
    public Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken);

    public Task<DensityEntry?> FindByNameAsync(string ingredientName, CancellationToken cancellationToken);

    public Task<DensityEntry> UpsertAsync(DensityEntry entry, CancellationToken cancellationToken);
}
