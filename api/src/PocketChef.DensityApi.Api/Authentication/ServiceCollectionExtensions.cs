namespace PocketChef.DensityApi.Api.Authentication;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApiKeyAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        var options = configuration.GetSection(ApiKeyOptions.SectionName).Get<ApiKeyOptions>()
            ?? throw new InvalidOperationException($"Missing '{ApiKeyOptions.SectionName}' configuration.");

        // Binding doesn't enforce `required`: a partial section binds with the other key
        // null, which passes startup but 500s every request in ApiKeyAuthorizer. Fail fast.
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
            throw new InvalidOperationException($"Missing or blank '{ApiKeyOptions.SectionName}:{keyName}' configuration.");
        }
    }
}
