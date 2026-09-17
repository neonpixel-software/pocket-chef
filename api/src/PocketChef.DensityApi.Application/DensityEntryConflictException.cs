namespace PocketChef.DensityApi.Application;

/// Thrown when a write loses a race against a concurrent write for the same (case-insensitive)
/// ingredient name — both requests pass FindByNameAsync's not-found check before either commits,
/// so the database's unique index is the only thing left to catch it.
public sealed class DensityEntryConflictException : Exception
{
    public DensityEntryConflictException(string ingredientName)
        : base($"Another request already created or updated an entry for '{ingredientName}'. Retry the request.")
    {
    }
}
