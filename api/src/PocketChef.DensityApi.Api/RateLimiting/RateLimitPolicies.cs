namespace PocketChef.DensityApi.Api.RateLimiting;

public static class RateLimitPolicies
{
    public const string Read = "read";

    /// Requests permitted per PermitWindow before the fixed-window limiter starts
    /// returning 429. The read key is baked into the app binary and extractable by
    /// anyone (issue #47), so this bounds a scraper pinning the VPS while staying
    /// generous enough for the client's periodic + manual refresh (Phase 10.2).
    public const int PermitLimit = 60;

    public static readonly TimeSpan PermitWindow = TimeSpan.FromMinutes(1);
}
