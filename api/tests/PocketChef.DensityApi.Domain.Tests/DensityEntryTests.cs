namespace PocketChef.DensityApi.Domain.Tests;

public class DensityEntryTests
{
    private static readonly DateTimeOffset SomeLastModifiedUtc = new(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Constructor_ThrowsForBlankIngredientName(string blankName)
    {
        var exception = Assert.Throws<ArgumentException>(() => new DensityEntry(Guid.NewGuid(), blankName, 0.53, SomeLastModifiedUtc));

        Assert.Equal("ingredientName", exception.ParamName);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Constructor_ThrowsForNonPositiveGramsPerMilliliter(double invalidGrams)
    {
        var exception = Assert.Throws<ArgumentException>(() => new DensityEntry(Guid.NewGuid(), "Flour", invalidGrams, SomeLastModifiedUtc));

        Assert.Equal("gramsPerMilliliter", exception.ParamName);
    }

    [Fact]
    public void Constructor_TrimsIngredientName()
    {
        var entry = new DensityEntry(Guid.NewGuid(), "  Flour  ", 0.53, SomeLastModifiedUtc);

        Assert.Equal("Flour", entry.IngredientName);
    }

    [Fact]
    public void Constructor_NormalizesIngredientNameToNfc()
    {
        // "café" spelled as "e" + combining acute accent, with padding around it.
        var entry = new DensityEntry(Guid.NewGuid(), "  cafe\u0301  ", 0.53, SomeLastModifiedUtc);

        Assert.Equal("café", entry.IngredientName);
    }

    [Fact]
    public void Constructor_SetsAllProperties()
    {
        var id = Guid.NewGuid();

        var entry = new DensityEntry(id, "Sugar", 0.85, SomeLastModifiedUtc);

        Assert.Equal(id, entry.Id);
        Assert.Equal("Sugar", entry.IngredientName);
        Assert.Equal(0.85, entry.GramsPerMilliliter);
        Assert.Equal(SomeLastModifiedUtc, entry.LastModifiedUtc);
    }
}
