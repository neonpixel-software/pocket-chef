using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace PocketChef.DensityApi.Api.Tests;

/// Shared test host config: Program.cs requires both ConnectionStrings:DensityApi and ApiKeys
/// to start at all, regardless of which endpoint a given test hits. ConnectionString defaults
/// to a value that's never actually connected to (fine for tests that never reach the
/// database, e.g. auth-rejection cases where the endpoint filter runs first) — tests that need
/// real data override it before first calling CreateClient()/Server, since ConfigureWebHost
/// runs at host-build time, which is lazy on first access.
///
/// Uses UseSetting(key, value), not ConfigureAppConfiguration + AddInMemoryCollection — the
/// latter's overrides arrive too late to be seen by Program.cs's eager
/// builder.Configuration.GetConnectionString(...)/GetSection(...).Get&lt;T&gt;() reads (confirmed
/// empirically: a test asserting on the resolved ApiKeyOptions showed appsettings.Development
/// .json's values winning over the AddInMemoryCollection override). UseSetting writes directly
/// into the host builder's settings before the app's builder is constructed, so Program.cs's
/// eager reads see it correctly.
public class DensityApiWebApplicationFactory : WebApplicationFactory<Program>
{
    public const string ReadApiKey = "test-read-key";
    public const string WriteApiKey = "test-write-key";

    public string ConnectionString { get; set; } = "Host=localhost;Port=5432;Database=densityapi_test;Username=test;Password=test";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("ConnectionStrings:DensityApi", ConnectionString);
        builder.UseSetting("ApiKeys:ReadApiKey", ReadApiKey);
        builder.UseSetting("ApiKeys:WriteApiKey", WriteApiKey);
    }
}
