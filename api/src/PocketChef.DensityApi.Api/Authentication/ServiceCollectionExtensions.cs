namespace PocketChef.DensityApi.Api.Authentication;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApiKeyAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        var options = configuration.GetSection(ApiKeyOptions.SectionName).Get<ApiKeyOptions>()
            ?? throw new InvalidOperationException($"Missing '{ApiKeyOptions.SectionName}' configuration.");

        services.AddSingleton(options);
        services.AddSingleton<ApiKeyAuthorizer>();
        return services;
    }
}
