namespace PocketChef.DensityApi.Api.Endpoints;

/// Deliberately excludes the domain entity's Id — an internal detail the client has no use for.
/// LastModifiedUtc is included ahead of when Phase 10.2 actually needs it (background sync
/// diffing) — the alternative is a second, coordinated API-contract-plus-schema change once a
/// client exists to consume it.
public sealed record DensityEntryResponse(string IngredientName, double GramsPerMilliliter, DateTimeOffset LastModifiedUtc);
