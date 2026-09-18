using System.Net;

namespace PocketChef.DensityApi.Api.Tests;

/// The rate limiter middleware runs before the API key filter, so unauthenticated requests
/// are enough to exercise it — no database needed, matching the auth-rejection tests' approach.
///
/// DensityApiWebApplicationFactory overrides the permit limit down to
/// ReadRateLimitPermitLimit (3) specifically so this test doesn't need 61 real requests to
/// trip a 60/minute window. That override applies to every test sharing this factory
/// instance (IClassFixture is one instance per test class) — a second test method added to
/// this class would immediately see 429s on its first request, since the shared limiter's
/// budget carries over within the class. Keep this class to the one test, or give any
/// additional rate-limit test its own factory instance.
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
