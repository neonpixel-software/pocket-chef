using System.Globalization;
using System.Threading.RateLimiting;

namespace PocketChef.DensityApi.Api.RateLimiting;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddDensityApiRateLimiting(this IServiceCollection services, IConfiguration configuration)
    {
        var readOptions = configuration.GetSection(ReadRateLimitOptions.SectionName).Get<ReadRateLimitOptions>()
            ?? new ReadRateLimitOptions();

        return services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            // Lets a rejected client know when to retry instead of hammering the endpoint
            // and collecting more 429s.
            options.OnRejected = (context, _) =>
            {
                if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
                {
                    context.HttpContext.Response.Headers.RetryAfter =
                        ((int)retryAfter.TotalSeconds).ToString(CultureInfo.InvariantCulture);
                }

                return ValueTask.CompletedTask;
            };

            // Partitioned per client (X-Forwarded-For, since nginx sits in front — see
            // deploy.md §1 — falling back to the connection's remote IP) rather than one
            // global bucket: otherwise a single noisy client exhausts the budget for
            // every other caller of this endpoint, authenticated or not.
            options.AddPolicy(RateLimitPolicies.Read, httpContext =>
            {
                var clientKey = httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                    ?? httpContext.Connection.RemoteIpAddress?.ToString()
                    ?? "unknown";

                return RateLimitPartition.GetFixedWindowLimiter(clientKey, _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = readOptions.PermitLimit,
                    Window = TimeSpan.FromSeconds(readOptions.WindowSeconds),
                    QueueLimit = 0
                });
            });
        });
    }
}
