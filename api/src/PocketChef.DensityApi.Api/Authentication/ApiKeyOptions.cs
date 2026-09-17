namespace PocketChef.DensityApi.Api.Authentication;

public sealed class ApiKeyOptions
{
    public const string SectionName = "ApiKeys";

    public required string ReadApiKey { get; init; }
    public required string WriteApiKey { get; init; }
}
