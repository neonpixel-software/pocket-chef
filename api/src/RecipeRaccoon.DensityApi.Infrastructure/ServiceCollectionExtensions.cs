using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using RecipeRaccoon.DensityApi.Application;

namespace RecipeRaccoon.DensityApi.Infrastructure;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddDensityApiInfrastructure(this IServiceCollection services, string connectionString)
    {
        services.AddDbContext<DensityApiDbContext>(options => options.UseNpgsql(connectionString));
        services.AddScoped<IDensityEntryRepository, DensityEntryRepository>();
        return services;
    }
}
