namespace PocketChef.DensityApi.Api.Authentication;

public static class RouteHandlerBuilderExtensions
{
    /// Rejects the request with 401 unless X-Api-Key matches a configured key at or above
    /// `tier`. Reads ApiKeyAuthorizer from DI per-request rather than baking it into a
    /// constructed filter instance — keeps this a plain extension method, no filter-factory
    /// ceremony needed for a check this small.
    public static RouteHandlerBuilder RequireApiKey(this RouteHandlerBuilder builder, ApiKeyTier tier)
    {
        return builder.AddEndpointFilter(async (context, next) =>
        {
            var authorizer = context.HttpContext.RequestServices.GetRequiredService<ApiKeyAuthorizer>();
            var providedKey = context.HttpContext.Request.Headers["X-Api-Key"].FirstOrDefault();

            if (!authorizer.Authorize(providedKey, tier))
            {
                return Results.Unauthorized();
            }

            return await next(context);
        });
    }
}
