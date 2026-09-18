using System.Net;
using PocketChef.DensityApi.Api.RateLimiting;

namespace PocketChef.DensityApi.Api.Tests;

/// The rate limiter middleware runs before the API key filter, so unauthenticated requests
/// are enough to exercise it — no database needed, matching the auth-rejection tests' approach.
public class DensityEntriesRateLimitTests : IClassFixture<DensityApiWebApplicationFactory>
{
    private readonly DensityApiWebApplicationFactory _factory;

    public DensityEntriesRateLimitTests(DensityApiWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Get_ExceedingPermitLimit_ReturnsTooManyRequests()
    {
        var client = _factory.CreateClient();

        HttpResponseMessage? response = null;
        for (var i = 0; i < RateLimitPolicies.PermitLimit + 1; i++)
        {
            response = await client.GetAsync("/density-entries");
        }

        Assert.Equal(HttpStatusCode.TooManyRequests, response!.StatusCode);
    }
}
