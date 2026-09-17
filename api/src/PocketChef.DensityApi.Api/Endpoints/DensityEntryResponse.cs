namespace PocketChef.DensityApi.Api.Endpoints;

/// Deliberately excludes the domain entity's Id — an internal detail the client has no use for.
public sealed record DensityEntryResponse(string IngredientName, double GramsPerCup);
