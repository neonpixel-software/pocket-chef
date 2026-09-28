using PocketChef.DensityApi.Application.Seeding;

namespace PocketChef.DensityApi.Application.Tests;

public class DensitySeedRowTests
{
    [Theory]
    [InlineData(HouseholdMeasure.Cup, 236.5882365)]
    [InlineData(HouseholdMeasure.Tablespoon, 14.78676478125)]
    [InlineData(HouseholdMeasure.Teaspoon, 4.92892159375)]
    public void Milliliters_IsTheUsCustomaryMeasure(HouseholdMeasure measure, double expected)
    {
        Assert.Equal(expected, measure.Milliliters(), precision: 10);
    }

    [Fact]
    public void GramsPerMilliliter_DividesTheWeightByTheVolume()
    {
        // All-purpose flour's SR Legacy cup portion: 1 cup = 125 g.
        var row = new DensitySeedRow("all-purpose flour", 1, 1, "cup", HouseholdMeasure.Cup, 125);

        Assert.Equal(0.5283, row.GramsPerMilliliter, precision: 4);
    }

    [Fact]
    public void GramsPerMilliliter_AccountsForThePortionAmount()
    {
        var row = new DensitySeedRow("salt", 1, 2, "tbsp", HouseholdMeasure.Tablespoon, 36);

        Assert.Equal(36 / (2 * HouseholdMeasures.CupMilliliters / 16), row.GramsPerMilliliter, precision: 10);
    }
}
