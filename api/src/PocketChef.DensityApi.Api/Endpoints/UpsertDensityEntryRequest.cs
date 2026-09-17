namespace PocketChef.DensityApi.Api.Endpoints;

public sealed record UpsertDensityEntryRequest(string IngredientName, double GramsPerCup);
