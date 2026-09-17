using PocketChef.DensityApi.Api.Authentication;
using PocketChef.DensityApi.Application;

namespace PocketChef.DensityApi.Api.Endpoints;

public static class DensityEntryEndpoints
{
    public static IEndpointRouteBuilder MapDensityEntryEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/density-entries", async (IDensityEntryService service, CancellationToken cancellationToken) =>
        {
            var entries = await service.GetAllAsync(cancellationToken);
            var response = entries.Select(entry => new DensityEntryResponse(entry.IngredientName, entry.GramsPerCup));
            return Results.Ok(response);
        }).RequireApiKey(ApiKeyTier.Read);

        return endpoints;
    }
}
