namespace PocketChef.DensityApi.Application.Seeding;

/// One seed value and the SR Legacy portion it was derived from, so any value can be
/// re-checked against FoodData Central: food <see cref="FdcId"/> lists a portion of
/// <see cref="Amount"/> × <see cref="Portion"/> weighing <see cref="Grams"/>.
/// <see cref="Portion"/> is the portion's `modifier` exactly as FDC gives it ("cup",
/// "cup, packed"); <see cref="Measure"/> is the household measure it names, used to
/// convert the portion to millilitres.
public sealed record DensitySeedRow(
    string IngredientName,
    int FdcId,
    double Amount,
    string Portion,
    HouseholdMeasure Measure,
    double Grams)
{
    public double GramsPerMilliliter => Grams / (Amount * Measure.Milliliters());
}
