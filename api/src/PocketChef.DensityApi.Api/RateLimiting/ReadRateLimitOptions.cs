namespace PocketChef.DensityApi.Api.RateLimiting;

public sealed class ReadRateLimitOptions
{
    public const string SectionName = "RateLimiting:Read";

    /// Requests permitted per WindowSeconds before the fixed-window limiter starts
    /// returning 429, per client (partitioned by IP — see ServiceCollectionExtensions).
    /// The read key is baked into the app binary and extractable by anyone (issue #47),
    /// so this bounds a single client pinning the VPS while staying generous enough for
    /// the client's periodic + manual refresh (Phase 10.2). Configuration-driven, not a
    /// production tuning need, so tests can override it to a small number.
    public int PermitLimit { get; init; } = 60;

    public int WindowSeconds { get; init; } = 60;
}
