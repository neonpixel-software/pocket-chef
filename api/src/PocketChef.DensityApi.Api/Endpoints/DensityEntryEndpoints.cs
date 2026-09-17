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

        endpoints.MapPost("/density-entries", async (UpsertDensityEntryRequest request, IDensityEntryService service, CancellationToken cancellationToken) =>
        {
            try
            {
                var entry = await service.UpsertAsync(request.IngredientName, request.GramsPerCup, cancellationToken);
                return Results.Ok(new DensityEntryResponse(entry.IngredientName, entry.GramsPerCup));
            }
            catch (ArgumentException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (DensityEntryConflictException ex)
            {
                return Results.Conflict(new { error = ex.Message });
            }
        }).RequireApiKey(ApiKeyTier.Write);

        return endpoints;
    }
}
