# Phase 8.3: Write endpoint + high-privilege key — design

Source: `PLAN.md` Phase 8.3 ("Write endpoints + high-privilege key").

Acceptance (from PLAN.md): write endpoints reject the read key; only the
write key can create/edit entries.

## Scope decisions

- **`POST /density-entries`** — one endpoint, not separate create/update
  ones. Body: `{ ingredientName, gramsPerCup }`. Calls the existing
  `IDensityEntryService.UpsertAsync` (built in 8.2, already does
  find-by-name then update-or-insert) — "add" and "edit" are the same
  call, matching PLAN.md's own "add/edit density entries" phrasing. No
  new Application/Infrastructure work needed; everything below this
  endpoint already exists.
- **Gated by `RequireApiKey(ApiKeyTier.Write)`** — the same filter
  extension from 8.2, just requiring the higher tier. A read key gets the
  same `401 Unauthorized` treatment as a missing/garbage key, matching
  8.2's uniform "not authorized for this tier" behavior rather than
  introducing a 401-vs-403 distinction that didn't exist before.
- **Validation boundary**: `DensityEntry`'s constructor already validates
  (blank name, non-positive grams) — this is the single source of
  validation truth, not duplicated at the endpoint. The endpoint catches
  the resulting `ArgumentException` and maps it to `400 Bad Request`
  rather than letting it surface as an unhandled 500 — the HTTP boundary
  is exactly where "trust internal code, validate at system boundaries"
  applies.
- **No admin UI** — `PLAN.md`'s own Backend section already says "No
  admin UI needed yet; a script is enough for now." Out of scope here by
  design, not an oversight.

## Testing plan

`WebApplicationFactory` integration tests (same pattern as 8.2's
`DensityEntriesAuthorizationTests`/`DensityEntriesDataTests`):
- No `X-Api-Key` → 401 (no DB touch, dummy connection string).
- Valid read key → 401 (wrong tier, no DB touch).
- Valid write key, invalid body (blank name / non-positive grams) → 400
  (no DB touch — validation fails before any repository call).
- Valid write key, new ingredient name → 200, `Testcontainers.PostgreSql`-
  backed, verifies the row was actually inserted.
- Valid write key, existing ingredient name → 200, verifies the existing
  row was updated in place (not duplicated) — proves upsert semantics
  through the HTTP layer, not just at the service layer (already covered
  by 8.2's `DensityEntryServiceTests`).

No new unit tests needed for `ApiKeyTier`/`ApiKeyAuthorizer`/
`IDensityEntryService` — all already covered by 8.2's tests, reused
as-is here.

Manual verification: same end-to-end pass as 8.1/8.2 — real Postgres via
Podman, real running app, `curl -X POST` with each key/body combination.
