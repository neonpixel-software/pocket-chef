using PocketChef.DensityApi.Domain;

namespace PocketChef.DensityApi.Domain.Tests;

public class DensityEntryTests
{
    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Constructor_ThrowsForBlankIngredientName(string blankName)
    {
        var exception = Assert.Throws<ArgumentException>(() => new DensityEntry(Guid.NewGuid(), blankName, 120));

        Assert.Equal("ingredientName", exception.ParamName);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Constructor_ThrowsForNonPositiveGramsPerCup(double invalidGrams)
    {
        var exception = Assert.Throws<ArgumentException>(() => new DensityEntry(Guid.NewGuid(), "Flour", invalidGrams));

        Assert.Equal("gramsPerCup", exception.ParamName);
    }

    [Fact]
    public void Constructor_TrimsIngredientName()
    {
        var entry = new DensityEntry(Guid.NewGuid(), "  Flour  ", 120);

        Assert.Equal("Flour", entry.IngredientName);
    }

    [Fact]
    public void Constructor_SetsAllProperties()
    {
        var id = Guid.NewGuid();

        var entry = new DensityEntry(id, "Sugar", 200);

        Assert.Equal(id, entry.Id);
        Assert.Equal("Sugar", entry.IngredientName);
        Assert.Equal(200, entry.GramsPerCup);
    }
}
