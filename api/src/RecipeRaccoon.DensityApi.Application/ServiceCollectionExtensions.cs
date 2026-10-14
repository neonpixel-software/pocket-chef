using Microsoft.Extensions.DependencyInjection;

namespace RecipeRaccoon.DensityApi.Application;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddDensityApiApplication(this IServiceCollection services)
    {
        services.AddScoped<IDensityEntryService, DensityEntryService>();
        return services;
    }
}
