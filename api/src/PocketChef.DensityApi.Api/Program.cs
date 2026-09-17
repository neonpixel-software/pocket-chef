using PocketChef.DensityApi.Application;
using PocketChef.DensityApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DensityApi")
    ?? throw new InvalidOperationException("Missing 'ConnectionStrings:DensityApi' configuration.");

builder.Services.AddDensityApiApplication();
builder.Services.AddDensityApiInfrastructure(connectionString);

var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.Run();

// Exposed for WebApplicationFactory<Program> in Api.Tests.
public partial class Program
{
}
