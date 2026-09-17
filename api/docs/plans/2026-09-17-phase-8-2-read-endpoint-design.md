# Phase 8.2: Read endpoint + low-privilege key — design

Source: `PLAN.md` Phase 8.2 ("Read endpoint + low-privilege key").

Acceptance (from PLAN.md): requests with a valid read key succeed;
requests without one, or with a write key used as read, still succeed
only for reads — a request with no key fails.

## Scope decisions

- **`GET /density-entries`** — returns every entry as
  `[{ ingredientName, gramsPerCup }]`. No `Id` exposed (internal detail,
  not needed by the client). No single-ingredient lookup endpoint — Phase
  10.1's "client fetches entries from the read endpoint and caches them
  on-device" describes a bulk fetch-then-cache pattern, not per-ingredient
  calls; not adding an endpoint nothing calls yet.
- **API key check is a `RequireApiKey(tier)` extension method on
  `RouteHandlerBuilder`** (an inline `AddEndpointFilter` lambda resolving
  `ApiKeyAuthorizer` from `HttpContext.RequestServices` per request), not
  the full ASP.NET Core authentication/authorization pipeline or a
  standalone `IEndpointFilter` class — matches the project's "no
  unnecessary ceremony" stance (same reasoning as skipping MediatR).
  Reads the key from an `X-Api-Key` header, compares against configured
  keys with `CryptographicOperations.FixedTimeEquals` (avoids timing
  attacks on key comparison — cheap to do correctly from the start).
- **Two keys already exist in this phase**, `ReadApiKey` and
  `WriteApiKey`, even though no write endpoint exists until 8.3 — required
  because 8.2's own acceptance criterion says a write key must also work
  against the read endpoint (write access implies read access). Configured
  the same way the DB connection string is (`appsettings`/environment,
  required at startup, no committed production secrets).
- **Tier model**: `ApiKeyTier { Read, Write }`, ordered so `Write`
  satisfies any requirement `Read` would. The filter is parameterized by
  the *minimum* tier an endpoint needs (`RequireApiKey(ApiKeyTier.Read)`),
  so Phase 8.3's write endpoints reuse the identical filter with
  `ApiKeyTier.Write` instead of duplicating auth logic.
- **This is an `Api`-layer concern**, not Domain/Application/Infrastructure
  — Clean Architecture's inner layers have no business knowing about HTTP
  headers or API keys at all.

## Testing plan

Matches `PLAN.md`'s own testing note for this layer: ".NET API layer:
integration tests against the actual Minimal API endpoints, specifically
proving read/write API key enforcement, not just happy-path responses."

- `WebApplicationFactory` tests against the real `/density-entries`
  endpoint:
  - No `X-Api-Key` header → 401.
  - Garbage/wrong key → 401.
  - Valid read key → 200.
  - Valid write key → 200 (proves the tier logic, not just "a key works").
- The failure/no-DB-needed cases reuse a shared dummy connection string —
  the filter runs before the handler, so a rejected request never touches
  the database.
- The 200-with-real-data cases use `Testcontainers.PostgreSql` (same
  pattern as `Infrastructure.Tests`) — seeds an entry, asserts the response
  body matches for both a read key and a write key. Runnable locally via
  Podman, not just in CI.
- Small unit tests for the tier-comparison logic itself
  (`ApiKeyTier.Write` satisfies a `Read` requirement, `ApiKeyTier.Read`
  does not satisfy a `Write` requirement) — pure logic, no host needed.

## Correction found during implementation

`WebApplicationFactory`'s usual `ConfigureWebHost(b => b.ConfigureAppConfiguration(...))` +
`AddInMemoryCollection(...)` pattern — used successfully for
`HealthEndpointTests`' connection-string override in 8.1 — turned out to
be a false positive: `/health` never touches configuration values beyond
what's needed to construct (not use) the `DbContext`, so that test never
actually exercised whether the override took effect. It doesn't:
confirmed empirically (a throwaway test asserting on the resolved
`ApiKeyOptions` showed `appsettings.Development.json`'s values winning
over the in-memory override), because `Program.cs` reads configuration
*eagerly* (`GetConnectionString(...)`, `GetSection(...).Get<T>()`) at
top-level-statement time, before `ConfigureAppConfiguration`'s override
is layered in. Switched `DensityApiWebApplicationFactory` to
`IWebHostBuilder.UseSetting(key, value)`, which writes directly into the
host builder's settings *before* the app's builder is constructed, so
eager reads see it correctly. Verified by rerunning the previously-failing
tests, which passed once switched.
