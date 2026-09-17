using Microsoft.EntityFrameworkCore;
using PocketChef.DensityApi.Application;
using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Infrastructure;

public sealed class DensityEntryRepository : IDensityEntryRepository
{
    private readonly DensityApiDbContext _context;

    public DensityEntryRepository(DensityApiDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken)
        => await _context.DensityEntries.AsNoTracking().OrderBy(entry => entry.IngredientName).ToListAsync(cancellationToken);

    public Task<DensityEntry?> FindByNameAsync(string ingredientName, CancellationToken cancellationToken)
        => _context.DensityEntries.AsNoTracking().FirstOrDefaultAsync(entry => entry.IngredientName == ingredientName, cancellationToken);

    public async Task<DensityEntry> UpsertAsync(DensityEntry entry, CancellationToken cancellationToken)
    {
        var existing = await _context.DensityEntries.FindAsync([entry.Id], cancellationToken);
        if (existing is null)
        {
            _context.DensityEntries.Add(entry);
        }
        else
        {
            // DensityEntry has no public setters, so EF falls back to writing the backing
            // fields directly for this copy — no CLR-level property setter needed.
            _context.Entry(existing).CurrentValues.SetValues(entry);
        }

        await _context.SaveChangesAsync(cancellationToken);
        return entry;
    }
}
