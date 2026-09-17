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
ENTRYPOINT ["dotnet", "PocketChef.DensityApi.Api.dll"]
