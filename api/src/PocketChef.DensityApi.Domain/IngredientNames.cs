using System.Text;

namespace PocketChef.DensityApi.Domain;

/// The canonical form of an ingredient name: Unicode-normalized to NFC and trimmed.
///
/// The database stores names in a citext column with a unique index, which folds case
/// but treats whitespace and Unicode canonical form as *significant*. So names that
/// read as the same to a person — "butter " vs "butter", "café" vs "e" + combining
/// accent — compare unequal unless canonicalized first: a lookup for the padded or
/// decomposed form misses the stored entry, the write then hits the unique index,
/// and the caller gets a 409 conflict for an entry that already exists (issue #55).
/// Every path that puts a name into a DensityEntry (the upsert service, seed data)
/// must pass it through <see cref="Canonicalize"/> so stored rows are always canonical.
/// A null or whitespace-only name throws <see cref="ArgumentException"/>.
public static class IngredientNames
{
    public static string Canonicalize(string ingredientName)
    {
        // Guard before normalizing: in .NET, Normalize on a null string throws a raw
        // NullReferenceException, not an ArgumentException. The write endpoint only
        // translates ArgumentException to 400, so without this a JSON null name (which
        // STJ happily binds to the non-nullable string parameter) would surface as a 500.
        ArgumentException.ThrowIfNullOrWhiteSpace(ingredientName);
        return ingredientName.Normalize(NormalizationForm.FormC).Trim();
    }
}
