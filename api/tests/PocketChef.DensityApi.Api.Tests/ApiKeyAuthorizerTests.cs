using PocketChef.DensityApi.Api.Authentication;

namespace PocketChef.DensityApi.Api.Tests;

public class ApiKeyAuthorizerTests
{
    private readonly ApiKeyAuthorizer _authorizer = new(new ApiKeyOptions
    {
        ReadApiKey = "the-read-key",
        WriteApiKey = "the-write-key"
    });

    [Fact]
    public void Authorize_ReadKeyAgainstReadRequirement_Succeeds()
    {
        Assert.True(_authorizer.Authorize("the-read-key", ApiKeyTier.Read));
    }

    [Fact]
    public void Authorize_WriteKeyAgainstReadRequirement_Succeeds()
    {
        Assert.True(_authorizer.Authorize("the-write-key", ApiKeyTier.Read));
    }

    [Fact]
    public void Authorize_WriteKeyAgainstWriteRequirement_Succeeds()
    {
        Assert.True(_authorizer.Authorize("the-write-key", ApiKeyTier.Write));
    }

    [Fact]
    public void Authorize_ReadKeyAgainstWriteRequirement_Fails()
    {
        Assert.False(_authorizer.Authorize("the-read-key", ApiKeyTier.Write));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("something-else-entirely")]
    public void Authorize_MissingOrWrongKey_Fails(string? providedKey)
    {
        Assert.False(_authorizer.Authorize(providedKey, ApiKeyTier.Read));
    }
}
