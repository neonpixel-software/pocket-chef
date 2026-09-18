using Microsoft.AspNetCore.RateLimiting;

namespace PocketChef.DensityApi.Api.RateLimiting;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddDensityApiRateLimiting(this IServiceCollection services)
    {
        return services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.AddFixedWindowLimiter(RateLimitPolicies.Read, limiterOptions =>
            {
                limiterOptions.PermitLimit = RateLimitPolicies.PermitLimit;
                limiterOptions.Window = RateLimitPolicies.PermitWindow;
                limiterOptions.QueueLimit = 0;
            });
        });
    }
}
