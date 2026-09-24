namespace PocketChef.DensityApi.Domain;

public sealed class DensityEntry
{
    public Guid Id { get; }
    public string IngredientName { get; }
    /// Stored in metric (g/ml), not per cup: "a cup" is 236.6 ml in the US but 250 ml in metric
    /// countries, so the client converts to whichever cup or spoon it displays. Sources quoted
    /// per cup are converted to g/ml when seeded.
    public double GramsPerMilliliter { get; }
    public DateTimeOffset LastModifiedUtc { get; }

    public DensityEntry(Guid id, string ingredientName, double gramsPerMilliliter, DateTimeOffset lastModifiedUtc)
    {
        if (string.IsNullOrWhiteSpace(ingredientName))
        {
            throw new ArgumentException("Ingredient name cannot be blank.", nameof(ingredientName));
        }

        if (gramsPerMilliliter <= 0)
        {
            throw new ArgumentException("Grams per milliliter must be positive.", nameof(gramsPerMilliliter));
        }

        Id = id;
        IngredientName = IngredientNames.Canonicalize(ingredientName);
        GramsPerMilliliter = gramsPerMilliliter;
        LastModifiedUtc = lastModifiedUtc;
    }
}
