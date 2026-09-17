# PocketChef.DensityApi

.NET 10 Minimal API serving ingredient density data (grams per cup). Clean
Architecture: `Domain` (entity + validation) → `Application` (services,
repository interface) → `Infrastructure` (EF Core + PostgreSQL) →
`Api` (Minimal API host).

## Local development

Uses [Podman](https://podman.io) rather than Docker — `podman machine init && podman machine start` once, then:

```sh
podman compose up -d                          # starts Postgres on localhost:5433
dotnet tool install --global dotnet-ef        # once
export PATH="$PATH:$HOME/.dotnet/tools"
dotnet ef database update \
  --project src/PocketChef.DensityApi.Infrastructure \
  --startup-project src/PocketChef.DensityApi.Api
dotnet run --project src/PocketChef.DensityApi.Api
```

`GET /health` confirms the host is up.

## Testing

```sh
dotnet test
```

`Infrastructure.Tests` uses `Testcontainers.PostgreSql` — spins up a real,
throwaway Postgres container per test class and runs actual EF Core
migrations against it. Needs a running Podman (or Docker) machine.
