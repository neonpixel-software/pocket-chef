using System.Security.Cryptography;
using System.Text;

namespace PocketChef.DensityApi.Api.Authentication;

public sealed class ApiKeyAuthorizer
{
    private readonly ApiKeyOptions _options;

    public ApiKeyAuthorizer(ApiKeyOptions options)
    {
        _options = options;
    }

    public bool Authorize(string? providedKey, ApiKeyTier requiredTier)
    {
        var matchedTier = MatchTier(providedKey);
        return matchedTier is not null && matchedTier >= requiredTier;
    }

    private ApiKeyTier? MatchTier(string? providedKey)
    {
        if (string.IsNullOrEmpty(providedKey))
        {
            return null;
        }

        if (ConstantTimeEquals(providedKey, _options.WriteApiKey))
        {
            return ApiKeyTier.Write;
        }

        if (ConstantTimeEquals(providedKey, _options.ReadApiKey))
        {
            return ApiKeyTier.Read;
        }

        return null;
    }

    private static bool ConstantTimeEquals(string a, string b)
    {
        var aBytes = Encoding.UTF8.GetBytes(a);
        var bBytes = Encoding.UTF8.GetBytes(b);

        // Different lengths aren't secret, so a short-circuit here doesn't leak anything
        // FixedTimeEquals was protecting; FixedTimeEquals itself requires equal-length spans.
        if (aBytes.Length != bBytes.Length)
        {
            return false;
        }

        return CryptographicOperations.FixedTimeEquals(aBytes, bBytes);
    }
}
