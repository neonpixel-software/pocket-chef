# Deploying the density API

Runbook for Phase 9.2 ("Deploy to Ubuntu VPS"). Written in response to
issue #47, which found the plan's acceptance criterion ("reachable over
HTTPS") had no documented path to get there. Unlike the design docs under
`docs/plans/`, this is operational reference — expected to be followed
(and updated) on every real deploy, not a point-in-time design record.

The container always serves plain HTTP on port 8080
(`ENV ASPNETCORE_URLS=http://+:8080` in `Dockerfile`); everything below is
about what sits in front of and around that container on the VPS.

## 1. TLS termination

The VPS already runs nginx for other services, so this reuses it rather
than introducing a second reverse proxy — no Caddy, no second cert-manager
to operate.

- Add a server block proxying the public hostname to the container on
  `127.0.0.1:8080` (bind the container's published port to loopback only —
  nginx is the only thing that should reach it directly):

  ```nginx
  server {
      listen 80;
      server_name density-api.pocketchef.example;  # replace with the real hostname

      location / {
          proxy_pass http://127.0.0.1:8080;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
      }
  }
  ```

- Issue and enroll the cert with `certbot --nginx -d density-api.pocketchef.example`.
  Certbot rewrites the block above to add the `listen 443 ssl` directives
  and the redirect from 80 → 443, and installs its own systemd timer for
  renewal — nothing further to configure.
- Confirm renewal works without intervention: `certbot renew --dry-run`.

## 2. Key storage

`ApiKeyOptions` (`Authentication/ApiKeyOptions.cs`) binds from an
`ApiKeys` config section with two required properties, `ReadApiKey` and
`WriteApiKey`. `Program.cs` throws at startup if that section is missing —
there's no way to run without both configured. Locally these come from
`appsettings.Development.json`; production `appsettings.json` deliberately
has no `ApiKeys` section and never should, since it's the one config file
that ships inside the built image.

In production, supply both keys — plus the DB connection string, same
reasoning — as environment variables, using ASP.NET Core's standard
double-underscore convention for nested config:

```
ConnectionStrings__DensityApi=Host=...;Port=5432;Database=densityapi;Username=...;Password=...
ApiKeys__ReadApiKey=<the key baked into the app binary>
ApiKeys__WriteApiKey=<Nick's private key>
```

Store these in a root-only env file outside the repo, e.g.
`/etc/pocket-chef-density-api/api.env` (`chmod 600`, owned by root), and
reference it from whatever runs the container (see §5). Never commit
these values, never bake them into the image, never put them in a file
under `api/`.

## 3. Postgres backups

Nothing existed here before this doc — also the reason PLAN.md's risk
table didn't list data loss as a risk at all (fixed alongside this).

The density table is small, hand-curated reference data with no
continuous user writes (writes only happen when Nick curates via the
write endpoint) — a nightly logical dump is enough. No WAL archiving or
point-in-time recovery; the ratio of operational complexity to what it'd
actually protect against doesn't justify it at this scale, and if the
worst happens, the data can also be re-seeded from Phase 9.1's source
data as a fallback.

A systemd timer running nightly:

```sh
pg_dump -Fc -h localhost -U densityapi densityapi \
  > /var/backups/pocket-chef-density-api/densityapi-$(date +%F).dump
find /var/backups/pocket-chef-density-api -name '*.dump' -mtime +14 -delete
```

Keep 14 days locally; copying dumps off-box is worth doing if the VPS
already has an off-box backup story for its other services — reuse that
rather than build a bespoke one here.

## 4. Rate limiting

`GET /density-entries` is gated by the read API key, but that key ships
inside the app binary — anyone can extract it. Client impact of the API
being unavailable is low (density values are cached locally on-device
once fetched), but nothing previously bounded how much load a scraper
using the extracted key could put on the VPS.

Added in this same change: a fixed-window rate limiter
(`RateLimiting/RateLimitPolicies.cs`,
`RateLimiting/ServiceCollectionExtensions.cs`), applied only to the read
endpoint via `.RequireRateLimiting(RateLimitPolicies.Read)` — the write
endpoint stays unlimited, since it's already gated behind a key only Nick
holds and is low-volume by design. Uses ASP.NET Core's built-in
`Microsoft.AspNetCore.RateLimiting` (part of the shared framework via
`Microsoft.NET.Sdk.Web` — no new package). 60 requests/minute,
`QueueLimit: 0` (reject immediately over the limit rather than queueing —
simplest behavior for a read-only endpoint), returns 429. Covered by
`DensityEntriesRateLimitTests`.

Nothing to configure on the VPS for this — it's in-process.

## 5. Process supervision

A systemd unit runs `podman compose up` for the stack, mirroring the
local-dev `compose.yml` pattern but extended with the API service itself
and pointed at the production env file from §2:

```ini
# /etc/systemd/system/pocket-chef-density-api.service
[Unit]
Description=Pocket Chef density API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/pocket-chef-density-api
EnvironmentFile=/etc/pocket-chef-density-api/api.env
ExecStart=/usr/bin/podman compose up
ExecStop=/usr/bin/podman compose down
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

`/opt/pocket-chef-density-api/compose.yml` on the VPS extends the
repo's local-dev `compose.yml` with the API service (publishing
`127.0.0.1:8080:8080`, per §1) and a `healthcheck:` wired to the existing
`/health` endpoint:

```yaml
services:
  api:
    image: <built/pushed image>
    ports:
      - "127.0.0.1:8080:8080"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    depends_on:
      - postgres
```

**Migrations are not run on boot.** Given the plan's own stance — density
data is "seeded once... curated by hand... no admin UI needed yet" — an
automatic migration running unattended against production data on every
restart is the wrong default: a bad migration would apply itself before
anyone reviews it. Migrations stay a deliberate manual step, run once
before restarting the service:

```sh
dotnet ef database update \
  --project src/PocketChef.DensityApi.Infrastructure \
  --startup-project src/PocketChef.DensityApi.Api \
  --connection "<production connection string>"
```
