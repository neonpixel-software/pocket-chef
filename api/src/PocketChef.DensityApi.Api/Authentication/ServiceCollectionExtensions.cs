namespace PocketChef.DensityApi.Api.Authentication;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApiKeyAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        var options = configuration.GetSection(ApiKeyOptions.SectionName).Get<ApiKeyOptions>()
            ?? throw new InvalidOperationException($"Missing '{ApiKeyOptions.SectionName}' configuration.");

        // Binding doesn't enforce `required`, so a partially-present section (e.g. only
        // ApiKeys__ReadApiKey set) binds with the other key null. Left unchecked, that
        // passes startup and then 500s on every request once ApiKeyAuthorizer compares
        // against the null key — fail here instead, as a clear deploy error.
        EnsureConfigured(options.ReadApiKey, nameof(ApiKeyOptions.ReadApiKey));
        EnsureConfigured(options.WriteApiKey, nameof(ApiKeyOptions.WriteApiKey));

        services.AddSingleton(options);
        services.AddSingleton<ApiKeyAuthorizer>();
        return services;
    }

    private static void EnsureConfigured(string? value, string keyName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new InvalidOperationException($"Missing '{ApiKeyOptions.SectionName}:{keyName}' configuration.");
        }
    }
}
