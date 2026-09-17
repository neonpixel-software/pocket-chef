using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PocketChef.DensityApi.Application;

namespace PocketChef.DensityApi.Infrastructure;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddDensityApiInfrastructure(this IServiceCollection services, string connectionString)
    {
        services.AddDbContext<DensityApiDbContext>(options => options.UseNpgsql(connectionString));
        services.AddScoped<IDensityEntryRepository, DensityEntryRepository>();
        return services;
    }
}
