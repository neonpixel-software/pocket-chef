using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using PocketChef.DensityApi.Api.Endpoints;
using PocketChef.DensityApi.Application;
using PocketChef.DensityApi.Domain;
using PocketChef.DensityApi.Infrastructure;
using Testcontainers.PostgreSql;

namespace PocketChef.DensityApi.Api.Tests;

public class DensityEntriesDataTests : IAsyncLifetime
{
    private static readonly DateTimeOffset SeededLastModifiedUtc = new(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);

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
        context.DensityEntries.Add(new DensityEntry(Guid.NewGuid(), "Flour", 120, SeededLastModifiedUtc));
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
        Assert.Equal(SeededLastModifiedUtc, entry.LastModifiedUtc);
    }

    [Fact]
    public async Task Get_WithValidWriteKey_AlsoSucceeds()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var response = await client.GetAsync("/density-entries");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Post_WithValidWriteKey_CreatesNewEntry()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var before = DateTimeOffset.UtcNow;
        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("Sugar", 200));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<DensityEntryResponse>();
        Assert.Equal("Sugar", body!.IngredientName);
        Assert.Equal(200, body.GramsPerCup);
        Assert.InRange(body.LastModifiedUtc, before, DateTimeOffset.UtcNow);

        var options = new DbContextOptionsBuilder<DensityApiDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;
        await using var context = new DensityApiDbContext(options);
        Assert.Equal(2, await context.DensityEntries.CountAsync());
    }

    [Fact]
    public async Task Post_WithValidWriteKey_ExistingIngredientName_UpdatesInPlace()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("Flour", 130));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<DensityEntryResponse>();
        Assert.Equal(130, body!.GramsPerCup);
        Assert.True(body.LastModifiedUtc > SeededLastModifiedUtc);

        var options = new DbContextOptionsBuilder<DensityApiDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;
        await using var context = new DensityApiDbContext(options);
        var entries = await context.DensityEntries.ToListAsync();
        var entry = Assert.Single(entries);
        Assert.Equal("Flour", entry.IngredientName);
        Assert.Equal(130, entry.GramsPerCup);
    }

    [Fact]
    public async Task Post_WithValidWriteKey_WhitespacePaddedName_UpdatesInPlaceInsteadOfConflicting()
    {
        // Issue #55: "Flour " differs from the seeded "Flour" only in trailing whitespace,
        // which the citext index treats as significant — before the service canonicalized
        // the name, this 409'd instead of merging.
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("Flour ", 130));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<DensityEntryResponse>();
        Assert.Equal("Flour", body!.IngredientName);
        Assert.Equal(130, body.GramsPerCup);

        var options = new DbContextOptionsBuilder<DensityApiDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;
        await using var context = new DensityApiDbContext(options);
        var entry = Assert.Single(await context.DensityEntries.ToListAsync());
        Assert.Equal("Flour", entry.IngredientName);
        Assert.Equal(130, entry.GramsPerCup);
    }

    [Fact]
    public async Task Post_WithValidWriteKey_BlankIngredientName_ReturnsBadRequest()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("   ", 200));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Post_WithValidWriteKey_NonPositiveGramsPerCup_ReturnsBadRequest()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("Sugar", 0));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Post_WhenServiceReportsAConflict_ReturnsConflict()
    {
        // A real concurrent-write race (two requests both passing FindByNameAsync before either
        // commits) is proven deterministically at the repository level in
        // DensityEntryRepositoryTests — it isn't reliably reproducible by racing two HTTP
        // requests through an in-process TestServer. This test instead swaps in a fake
        // IDensityEntryService that always throws DensityEntryConflictException, to
        // deterministically verify the endpoint's own translation of that exception into 409.
        await using var factory = _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IDensityEntryService>();
                services.AddScoped<IDensityEntryService>(_ => new AlwaysConflictingDensityEntryService());
            });
        });
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Api-Key", DensityApiWebApplicationFactory.WriteApiKey);

        var response = await client.PostAsJsonAsync("/density-entries", new UpsertDensityEntryRequest("Cocoa", 90));

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    private sealed class AlwaysConflictingDensityEntryService : IDensityEntryService
    {
        public Task<IReadOnlyList<DensityEntry>> GetAllAsync(CancellationToken cancellationToken)
            => throw new NotSupportedException();

        public Task<DensityEntry> UpsertAsync(string ingredientName, double gramsPerCup, CancellationToken cancellationToken)
            => throw new DensityEntryConflictException(ingredientName);
    }
}
