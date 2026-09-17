using Microsoft.EntityFrameworkCore;
using Npgsql;
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

        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Two concurrent writes for the same (case-insensitive) name can both pass the
            // service's FindByNameAsync-then-insert check before either commits — only the
            // database's unique index actually catches the second one. Translate the raw
            // Npgsql/EF exception into something the Api layer can map to a clean response
            // without depending on persistence-specific exception types.
            throw new DensityEntryConflictException(entry.IngredientName);
        }

        return entry;
    }
}
