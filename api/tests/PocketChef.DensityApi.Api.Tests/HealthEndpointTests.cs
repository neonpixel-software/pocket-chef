using System.Net;

namespace PocketChef.DensityApi.Api.Tests;

public class HealthEndpointTests : IClassFixture<DensityApiWebApplicationFactory>
{
    private readonly DensityApiWebApplicationFactory _factory;

    public HealthEndpointTests(DensityApiWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Health_ReturnsOk()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
