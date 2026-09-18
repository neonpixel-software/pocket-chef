using System.Net;

namespace PocketChef.DensityApi.Api.Tests;

/// The rate limiter middleware runs before the API key filter, so unauthenticated requests
/// are enough to exercise it — no database needed, matching the auth-rejection tests' approach.
///
/// DensityApiWebApplicationFactory.ReadRateLimitPermitLimit documents the shared-budget
/// constraint this relies on (this test alone consumes it entirely by design).
public class DensityEntriesRateLimitTests : IClassFixture<DensityApiWebApplicationFactory>
{
    private readonly DensityApiWebApplicationFactory _factory;

    public DensityEntriesRateLimitTests(DensityApiWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Get_ExceedingPermitLimit_ReturnsTooManyRequestsWithRetryAfter()
    {
        var client = _factory.CreateClient();

        HttpResponseMessage? response = null;
        for (var i = 0; i < DensityApiWebApplicationFactory.ReadRateLimitPermitLimit + 1; i++)
        {
            response = await client.GetAsync("/density-entries");
        }

        Assert.Equal(HttpStatusCode.TooManyRequests, response!.StatusCode);
        Assert.True(response.Headers.RetryAfter is not null, "Expected a Retry-After header on a 429 response.");
    }
}
