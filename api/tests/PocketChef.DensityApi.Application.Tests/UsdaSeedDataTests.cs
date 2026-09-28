using PocketChef.DensityApi.Application.Seeding;
using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Application.Tests;

public class UsdaSeedDataTests
{
    [Fact]
    public void Rows_AreNotEmpty()
    {
        Assert.NotEmpty(UsdaSeedData.Rows);
    }

    [Fact]
    public void Names_AreCanonicalAndLowerCase()
    {
        Assert.All(UsdaSeedData.Rows, row =>
        {
            Assert.Equal(IngredientNames.Canonicalize(row.IngredientName), row.IngredientName);
            Assert.Equal(row.IngredientName.ToLowerInvariant(), row.IngredientName);
        });
    }

    [Fact]
    public void Names_AreUniqueIgnoringCase()
    {
        // The table's citext index would reject the second row; the seeder would skip it.
        var duplicates = UsdaSeedData.Rows
            .GroupBy(row => row.IngredientName, StringComparer.OrdinalIgnoreCase)
            .Where(group => group.Count() > 1)
            .Select(group => group.Key);

        Assert.Empty(duplicates);
    }

    [Fact]
    public void Portions_NameTheMeasureTheyAreConvertedWith()
    {
        Assert.All(UsdaSeedData.Rows, row =>
        {
            // FDC abbreviates spoons on most foods but spells them out on some ("tablespoon").
            string[] prefixes = row.Measure switch
            {
                HouseholdMeasure.Cup => ["cup"],
                HouseholdMeasure.Tablespoon => ["tbsp", "tablespoon"],
                HouseholdMeasure.Teaspoon => ["tsp", "teaspoon"],
                _ => throw new ArgumentOutOfRangeException(nameof(row), row.Measure, null),
            };
            Assert.Contains(prefixes, prefix => row.Portion.StartsWith(prefix, StringComparison.Ordinal));
        });
    }

    [Fact]
    public void Rows_CiteAnFdcFoodAndAPositivePortion()
    {
        Assert.All(UsdaSeedData.Rows, row =>
        {
            Assert.True(row.FdcId > 0, $"{row.IngredientName} has no FDC ID");
            Assert.True(row.Amount > 0, $"{row.IngredientName} has no portion amount");
            Assert.True(row.Grams > 0, $"{row.IngredientName} has no portion weight");
        });
    }

    [Fact]
    public void Densities_AreWithinTheRangeOfKitchenIngredients()
    {
        // From puffed cereals (~0.1 g/ml) to syrups and honey (~1.4 g/ml). A value outside
        // this range means the wrong portion row, or a cup read as a spoon.
        Assert.All(UsdaSeedData.Rows, row => Assert.InRange(row.GramsPerMilliliter, 0.05, 2.0));
    }

    [Theory]
    [InlineData("all-purpose flour", 0.50, 0.56)]
    [InlineData("granulated sugar", 0.82, 0.88)]
    [InlineData("butter", 0.93, 0.99)]
    public void Staples_HaveSensibleDensities(string ingredientName, double min, double max)
    {
        var row = Assert.Single(UsdaSeedData.Rows, row => row.IngredientName == ingredientName);

        Assert.InRange(row.GramsPerMilliliter, min, max);
    }
}
