namespace PocketChef.DensityApi.Api.Authentication;

/// Ordered so a higher tier satisfies any lower tier's requirement — a write key can do
/// everything a read key can.
public enum ApiKeyTier
{
    Read = 0,
    Write = 1
}
