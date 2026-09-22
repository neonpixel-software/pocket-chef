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

The `Infrastructure.Tests` and `Api.Tests` data tests use
`Testcontainers.PostgreSql` — a real, throwaway Postgres container per
test method, with the actual EF Core migrations run against it. No extra
setup: Testcontainers talks to the Docker Engine API over
`/var/run/docker.sock`, which is exactly the socket `podman machine`
exposes on the host — so the only prerequisite is the machine from Local
development being running (`podman machine start` again after a reboot).
The first run pulls `postgres:17` into the machine.
