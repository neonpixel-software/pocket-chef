namespace PocketChef.DensityApi.Domain;

public sealed class DensityEntry
{
    public Guid Id { get; }
    public string IngredientName { get; }
    public double GramsPerCup { get; }

    public DensityEntry(Guid id, string ingredientName, double gramsPerCup)
    {
        if (string.IsNullOrWhiteSpace(ingredientName))
        {
            throw new ArgumentException("Ingredient name cannot be blank.", nameof(ingredientName));
        }

        if (gramsPerCup <= 0)
        {
            throw new ArgumentException("Grams per cup must be positive.", nameof(gramsPerCup));
        }

        Id = id;
        IngredientName = ingredientName.Trim();
        GramsPerCup = gramsPerCup;
    }
}
