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
        // The database's citext index folds case but treats whitespace and Unicode canonical
        // form as significant (issue #55): a padded or decomposed name would miss the
        // lookup, then hit the unique index on insert — a 409 conflict for an entry that
        // already exists. Canonicalize before looking so such upserts merge in place. The
        // same normalization will be needed client-side when Phase 10 matches ingredient
        // names against cached entries.
        var name = IngredientNames.Canonicalize(ingredientName);
        var existing = await _repository.FindByNameAsync(name, cancellationToken);
        // LastModifiedUtc is always "now" on a write, whether this creates a new row or
        // updates an existing one — it exists so a future client (Phase 10.2's periodic
        // refresh) can ask "what changed since I last synced?" without downloading the whole
        // table every time.
        var entry = new DensityEntry(existing?.Id ?? Guid.NewGuid(), name, gramsPerCup, DateTimeOffset.UtcNow);
        return await _repository.UpsertAsync(entry, cancellationToken);
    }
}
