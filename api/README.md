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

## Data source

Seed density values come from [USDA FoodData Central](https://fdc.nal.usda.gov/)
(SR Legacy, "1 cup" portion weights), which is public domain under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). Each seed entry
cites its FDC ID. Don't add values copied from sources whose license doesn't
permit redistribution in this GPL-3.0 repo (see PLAN.md Phase 9.1).

## Testing

```sh
dotnet test
```

The `Infrastructure.Tests` and `Api.Tests` data tests use
`Testcontainers.PostgreSql` — a real, throwaway Postgres container per
test method, with the actual EF Core migrations run against it.
Testcontainers talks to the Docker Engine API over the standard
`/var/run/docker.sock` path: `podman machine` forwards the in-machine API
socket to `~/.local/share/containers/podman/machine/podman.sock`, and the
`podman-mac-helper` system service (one-time `sudo podman-mac-helper
install`) keeps the `/var/run/docker.sock` link pointed at it. The only
prerequisite after that is a running Podman machine (`podman machine
start` again after a reboot). If the helper is missing or
`/var/run/docker.sock` is in use by another runtime, `podman machine
start` prints a `DOCKER_HOST` export for the machine socket — run it for
the test session, or install the helper.
The first run pulls `postgres:17` into the machine.
