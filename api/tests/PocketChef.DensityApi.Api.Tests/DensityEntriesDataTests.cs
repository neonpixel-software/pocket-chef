using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using PocketChef.DensityApi.Api.Endpoints;
using PocketChef.DensityApi.Domain;
using PocketChef.DensityApi.Infrastructure;
using Testcontainers.PostgreSql;

namespace PocketChef.DensityApi.Api.Tests;

public class DensityEntriesDataTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder("postgres:17")
        .Build();

    private DensityApiWebApplicationFactory _factory = null!;

    public async Task InitializeAsync()
    {
        await _container.StartAsync();

        var options = new DbContextOptionsBuilder<DensityApiDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;
        await using var context = new DensityApiDbContext(options);
        await context.Database.MigrateAsync();
        context.DensityEntries.Add(new DensityEntry(Guid.NewGuid(), "Flour", 120));
        await context.SaveChangesAsync();

        _factory = new DensityApiWebApplicationFactory { ConnectionString = _container.GetConnectionString() };
    }

    public async Task DisposeAsync()
    {
        await _factory.DisposeAsync();
        await _container.DisposeAsync();
    }

    [Fact]
    public async Task Get_WithValidReadKey_ReturnsSeededEntries()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.ReadApiKey);

        var response = await client.GetAsync("/density-entries");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var entries = await response.Content.ReadFromJsonAsync<List<DensityEntryResponse>>();
        var entry = Assert.Single(entries!);
        Assert.Equal("Flour", entry.IngredientName);
        Assert.Equal(120, entry.GramsPerCup);
    }

    [Fact]
    public async Task Get_WithValidWriteKey_AlsoSucceeds()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var response = await client.GetAsync("/density-entries");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
