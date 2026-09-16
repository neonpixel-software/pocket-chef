# Phase 8.1: Density API scaffold — design

Source: `PLAN.md` Phase 8.1 ("API scaffold + `DensityEntry` model").

Acceptance (from PLAN.md): API runs locally, entries can be created/read
directly against the database. Also add a `nuget` ecosystem entry to
`.github/dependabot.yml`.

## Environment note: Podman, not Docker

This environment has no Docker; Podman was installed and its machine
started for this work (`brew install podman`, `podman machine init/start`).
Podman's machine forwards a Docker-compatible API socket at
`/var/run/docker.sock` by default, so `Testcontainers` for .NET — which
talks to the standard Docker API — works with zero special configuration.
Verified with `podman run --rm hello-world` before starting. This means,
unlike Phase 5/6/7's AI/hardware gaps, the Infrastructure-layer integration
tests below **are** runnable and verified locally in this environment, not
just in CI.

## Scope decisions

- **.NET 10** (matches the SDK already installed here).
- **Solution layout**: `api/PocketChef.DensityApi.sln` with `src/` (Domain,
  Application, Infrastructure, Api) and `tests/` (one test project per
  src layer). Mirrors the Swift app's Clean Architecture layering.
- **Repository interface lives in Application, not Domain** — Domain stays
  a pure model + validation rules with zero dependencies; Application
  declares what it needs from Infrastructure (`IDensityEntryRepository`)
  without depending on it. Common ASP.NET Core Clean Architecture
  convention (e.g. the widely-used Jason Taylor template), matching what
  `PLAN.md`'s architecture section is drawing from.
- **One model, not two**: `DensityEntry` is both the domain entity and the
  EF Core-mapped type (no separate persistence DTO). Validation
  (non-blank trimmed name, positive grams-per-cup) lives in the
  constructor; EF Core is configured to use a private parameterless
  constructor + backing fields so the public constructor's validation
  can't be bypassed by materialization.
- **Case-insensitive unique ingredient name**: enforced via a Postgres
  `citext` column + unique index in Infrastructure — mirrors the Swift
  app's case-insensitive tag-name matching (`FindOrCreateTagUseCase`).
  Upsert-by-name (find existing by name, update or insert) is the
  Application service's job, not the repository's.
- **Api host scope for 8.1**: just enough to prove the host runs — DI
  wiring for the DbContext/repository/service, and a `/health` endpoint.
  The actual density read/write endpoints (with API-key enforcement) are
  Phase 8.2/8.3 per `PLAN.md`'s own phasing — out of scope here.
- **Local dev**: `podman-compose.yml` (Podman's compose tooling, not
  Docker's) runs a Postgres container for `dotnet run` against locally.
  A `Dockerfile` for the Api host is included now (used for eventual VPS
  deployment in Phase 9.2) but not exercised by this PR beyond `docker
  build`-style validation.
- **CI**: new GitHub Actions workflow (`api-ci.yml`), scoped via
  `paths: [api/**]` so it doesn't run on Swift-only PRs, on `ubuntu-latest`
  (has Docker preinstalled, so Testcontainers works there unmodified even
  though local dev here uses Podman). SonarCloud wiring for `api/` is a
  separate concern needing a new SonarCloud project — tracked separately,
  not blocking this scaffold.

## Testing plan

- **Domain.Tests**: `DensityEntry` constructor validation — blank name
  throws, non-positive grams-per-cup throws, name gets trimmed. Plain
  xUnit, zero dependencies.
- **Application.Tests**: `DensityEntryService` against a fake
  `IDensityEntryRepository` (hand-written fake, not a mocking framework —
  matches the Swift app's testing style) — upsert finds-and-updates an
  existing entry by name vs. creates a new one, get-all passes through.
- **Infrastructure.Tests**: `Testcontainers.PostgreSql` spins up a real
  Postgres container per test class, runs actual EF Core migrations
  against it, proves `DensityEntryRepository` CRUD and the case-insensitive
  unique constraint for real. Runnable and verified locally via Podman.
- **Api.Tests**: `WebApplicationFactory`-based test hitting `/health`,
  proving the host actually starts and wires its DI graph correctly.
