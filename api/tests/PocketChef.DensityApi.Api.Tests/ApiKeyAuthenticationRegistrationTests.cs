using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PocketChef.DensityApi.Api.Authentication;

namespace PocketChef.DensityApi.Api.Tests;

/// Exercises AddApiKeyAuthentication directly against in-memory configuration rather than
/// through DensityApiWebApplicationFactory: the factory always sets both keys, and the
/// behavior under test is a startup-time throw, which is simpler to assert on here than via
/// a host that fails to build.
public class ApiKeyAuthenticationRegistrationTests
{
    [Fact]
    public void AddApiKeyAuthentication_BothKeysConfigured_RegistersOptions()
    {
        var services = new ServiceCollection();

        services.AddApiKeyAuthentication(BuildConfiguration(("ReadApiKey", "r"), ("WriteApiKey", "w")));

        var options = services.BuildServiceProvider().GetRequiredService<ApiKeyOptions>();
        Assert.Equal("r", options.ReadApiKey);
        Assert.Equal("w", options.WriteApiKey);
    }

    [Fact]
    public void AddApiKeyAuthentication_SectionMissing_Throws()
    {
        var exception = Assert.Throws<InvalidOperationException>(
            () => new ServiceCollection().AddApiKeyAuthentication(BuildConfiguration()));

        Assert.Contains(ApiKeyOptions.SectionName, exception.Message);
    }

    // A partially-configured section used to bind successfully with the missing key left
    // null, then 500 on every request once ApiKeyAuthorizer compared against it (issue #57).
    [Theory]
    [InlineData("ReadApiKey", "WriteApiKey")]
    [InlineData("WriteApiKey", "ReadApiKey")]
    public void AddApiKeyAuthentication_OneKeyMissing_ThrowsNamingTheMissingKey(string presentKey, string missingKey)
    {
        var exception = Assert.Throws<InvalidOperationException>(
            () => new ServiceCollection().AddApiKeyAuthentication(BuildConfiguration((presentKey, "some-key"))));

        Assert.Contains($"{ApiKeyOptions.SectionName}:{missingKey}", exception.Message);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void AddApiKeyAuthentication_KeyBlank_Throws(string blankValue)
    {
        var exception = Assert.Throws<InvalidOperationException>(
            () => new ServiceCollection().AddApiKeyAuthentication(
                BuildConfiguration(("ReadApiKey", "r"), ("WriteApiKey", blankValue))));

        // "blank", not just "Missing": the variable exists, so don't send someone hunting for it.
        Assert.Contains($"blank '{ApiKeyOptions.SectionName}:WriteApiKey'", exception.Message);
    }

    private static IConfiguration BuildConfiguration(params (string Key, string Value)[] apiKeys) =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(apiKeys.Select(k =>
                new KeyValuePair<string, string?>($"{ApiKeyOptions.SectionName}:{k.Key}", k.Value)))
            .Build();
}
