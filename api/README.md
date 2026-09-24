# PocketChef.DensityApi

.NET 10 Minimal API serving ingredient density data (grams per millilitre). Clean
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

## Seed data

The initial density entries (Phase 9.1) are derived from
[USDA FoodData Central](https://fdc.nal.usda.gov) household-measure portion
weights, converted to grams per millilitre. FoodData Central data is in the
public domain and published under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/), so it can
ship in this MIT-licensed repo. Each seed row records its FDC ID, food
description, and the portion it was converted from.

> U.S. Department of Agriculture, Agricultural Research Service.
> FoodData Central. fdc.nal.usda.gov.

Don't add seed rows from sources without an open license (brand weight
charts, scraped cooking sites) — see PLAN.md Phase 9.1.

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
