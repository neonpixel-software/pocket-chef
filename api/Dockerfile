FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY PocketChef.DensityApi.slnx .
COPY src/PocketChef.DensityApi.Domain/PocketChef.DensityApi.Domain.csproj src/PocketChef.DensityApi.Domain/
COPY src/PocketChef.DensityApi.Application/PocketChef.DensityApi.Application.csproj src/PocketChef.DensityApi.Application/
COPY src/PocketChef.DensityApi.Infrastructure/PocketChef.DensityApi.Infrastructure.csproj src/PocketChef.DensityApi.Infrastructure/
COPY src/PocketChef.DensityApi.Api/PocketChef.DensityApi.Api.csproj src/PocketChef.DensityApi.Api/
RUN dotnet restore src/PocketChef.DensityApi.Api/PocketChef.DensityApi.Api.csproj

COPY src/ src/
RUN dotnet publish src/PocketChef.DensityApi.Api/PocketChef.DensityApi.Api.csproj -c Release -o /app

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
ENTRYPOINT ["dotnet", "PocketChef.DensityApi.Api.dll"]
