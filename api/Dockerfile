FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY RecipeRaccoon.DensityApi.slnx .
COPY src/RecipeRaccoon.DensityApi.Domain/RecipeRaccoon.DensityApi.Domain.csproj src/RecipeRaccoon.DensityApi.Domain/
COPY src/RecipeRaccoon.DensityApi.Application/RecipeRaccoon.DensityApi.Application.csproj src/RecipeRaccoon.DensityApi.Application/
COPY src/RecipeRaccoon.DensityApi.Infrastructure/RecipeRaccoon.DensityApi.Infrastructure.csproj src/RecipeRaccoon.DensityApi.Infrastructure/
COPY src/RecipeRaccoon.DensityApi.Api/RecipeRaccoon.DensityApi.Api.csproj src/RecipeRaccoon.DensityApi.Api/
RUN dotnet restore src/RecipeRaccoon.DensityApi.Api/RecipeRaccoon.DensityApi.Api.csproj

COPY src/ src/
RUN dotnet publish src/RecipeRaccoon.DensityApi.Api/RecipeRaccoon.DensityApi.Api.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
# curl: the base image ships without it or wget, but compose's healthcheck needs
# something to probe /health with (issue #47 review).
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
# Non-root: $APP_UID is the non-root user baked into Microsoft's official ASP.NET Core image
# specifically for this purpose, rather than running as root/containerAdministrator.
USER $APP_UID
ENTRYPOINT ["dotnet", "RecipeRaccoon.DensityApi.Api.dll"]
