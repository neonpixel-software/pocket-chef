using System.Net;
using System.Net.Http.Json;
using PocketChef.DensityApi.Api.Endpoints;

namespace PocketChef.DensityApi.Api.Tests;

/// The 401 cases never reach the database (the API key filter runs before the handler), so
/// these reuse the default dummy connection string — no Testcontainers needed here.
public class DensityEntriesAuthorizationTests : IClassFixture<DensityApiWebApplicationFactory>
{
    private readonly DensityApiWebApplicationFactory _factory;

    public DensityEntriesAuthorizationTests(DensityApiWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Get_WithNoApiKey_ReturnsUnauthorized()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/density-entries");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Get_WithWrongApiKey_ReturnsUnauthorized()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", "not-a-real-key");

        var response = await client.GetAsync("/density-entries");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Post_WithNoApiKey_ReturnsUnauthorized()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("Sugar", 0.85));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Post_WithReadApiKey_ReturnsUnauthorized()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.ReadApiKey);

        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("Sugar", 0.85));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
