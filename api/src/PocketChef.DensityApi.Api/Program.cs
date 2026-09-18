using PocketChef.DensityApi.Api.Authentication;
using PocketChef.DensityApi.Api.Endpoints;
using PocketChef.DensityApi.Api.RateLimiting;
using PocketChef.DensityApi.Application;
using PocketChef.DensityApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DensityApi")
    ?? throw new InvalidOperationException("Missing 'ConnectionStrings:DensityApi' configuration.");

builder.Services.AddDensityApiApplication();
builder.Services.AddDensityApiInfrastructure(connectionString);
builder.Services.AddApiKeyAuthentication(builder.Configuration);
builder.Services.AddDensityApiRateLimiting(builder.Configuration);

var app = builder.Build();

app.UseRateLimiter();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
app.MapDensityEntryEndpoints();

await app.RunAsync();

// Exposed for WebApplicationFactory<Program> in Api.Tests.
public partial class Program
{
    protected Program() { }
}
