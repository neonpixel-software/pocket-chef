namespace PocketChef.DensityApi.Application.Seeding;

/// The US household measures that USDA SR Legacy portions are given in (the unit sits in
/// `food_portion.modifier`, e.g. "cup" or "tbsp").
public enum HouseholdMeasure
{
    Cup,
    Tablespoon,
    Teaspoon,
}

public static class HouseholdMeasures
{
    /// One US customary cup. A tablespoon is 1/16 of it and a teaspoon 1/48.
    public const double CupMilliliters = 236.5882365;

    public static double Milliliters(this HouseholdMeasure measure) => measure switch
    {
        HouseholdMeasure.Cup => CupMilliliters,
        HouseholdMeasure.Tablespoon => CupMilliliters / 16,
        HouseholdMeasure.Teaspoon => CupMilliliters / 48,
        _ => throw new ArgumentOutOfRangeException(nameof(measure), measure, null),
    };
}
