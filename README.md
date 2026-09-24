# Pocket Chef

A NeonPixel app for macOS, iPadOS, and iOS. Gather recipes with zero friction: type one in or paste a URL, and it's stored clean — no ads, no life story, just the recipe.

> ⚠️ **Disclaimer:** This repository was built by three LLMs (large language models). The code was written by language models, but it holds the same standard as anything else here: it has to pass CI, the test suites, and the SonarCloud quality gate before it lands.

[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=neonpixel-software_pocket-chef&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=neonpixel-software_pocket-chef)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=neonpixel-software_pocket-chef&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=neonpixel-software_pocket-chef)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=neonpixel-software_pocket-chef&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=neonpixel-software_pocket-chef)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=neonpixel-software_pocket-chef&metric=coverage)](https://sonarcloud.io/summary/new_code?id=neonpixel-software_pocket-chef)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=neonpixel-software_pocket-chef&metric=duplicated_lines_density)](https://sonarcloud.io/summary/new_code?id=neonpixel-software_pocket-chef)

## Features

- **Zero-friction capture** — two clearly presented options on the add-recipe screen: *Type it* (free text) or *Paste a link* (URL). Apple Intelligence structures or extracts the recipe entirely on-device — no server round-trip. Devices without Apple Intelligence fall back straight to a blank structured form.
- **Review before save** — every capture path lands on an editable review screen. Nothing saves unreviewed.
- **Tags** — preset tags (breakfast, lunch, dinner, dessert, snack) plus unlimited custom tags, multiple per recipe, with tag filtering on the list.

## Privacy

Pocket Chef collects **no** user data, shows **no** ads, and is completely anonymous. Recipe capture runs on-device via Apple Intelligence — a pasted URL is fetched directly from its source site, never proxied through our servers — and the only other planned network activity is the density-data API. The App Store privacy declaration will be "data not collected".

## Repository layout

```
app/    SwiftUI client (macOS, iPadOS, iOS) — one shared codebase, Clean Architecture + MVVM, SwiftData
api/    .NET 10 density API (Minimal APIs, EF Core + PostgreSQL) — serves ingredient density data only
PLAN.md Source of truth for architecture and the phase-by-phase implementation plan
```

The API does exactly one job — serve ingredient density data for unit conversion — and is fully decoupled from the client: it is not involved in recipe storage, sync, or capture.

## Development

### Swift app (`app/`)

The Xcode project is generated from [`project.yml`](app/project.yml) with [XcodeGen](https://github.com/yonaskolb/XcodeGen), from the `app/` directory:

```sh
xcodegen generate
```

Then open `app/PocketChef.xcodeproj` and use the `PocketChef-iOS` / `PocketChef-macOS` schemes (build, test, coverage). Deployment targets are iOS 26 / macOS 26; the UI is localized into English, Spanish, French, German, and Dutch.

### Density API (`api/`)

Local development uses [Podman](https://podman.io) for the PostgreSQL container. From the `api/` directory:

```sh
podman compose up -d        # starts Postgres on localhost:5433
dotnet ef database update \
  --project src/PocketChef.DensityApi.Infrastructure \
  --startup-project src/PocketChef.DensityApi.Api
dotnet run --project src/PocketChef.DensityApi.Api
dotnet test                 # unit + Testcontainers-backed integration tests
```

See [`api/README.md`](api/README.md) for full details (one-time `dotnet-ef` install, the Testcontainers/Podman socket setup), and [`api/docs/deploy.md`](api/docs/deploy.md) for the production deployment runbook (TLS, key storage, backups, rate limiting, process supervision) — documented, but not yet executed against the real VPS.

## Documentation

- [`PLAN.md`](PLAN.md) — architecture, data model, and the phase-by-phase plan with current status
- [`app/docs/plans/`](app/docs/plans/) — Swift app design docs (entry form, tagging, capture, localization)
- [`api/docs/plans/`](api/docs/plans/) — density API design docs
- [`api/docs/deploy.md`](api/docs/deploy.md) — operational deployment runbook (documented, not yet executed against the real VPS — Phase 9.2)

Development proceeds in vertical slices (see `PLAN.md`); the project is not yet at its full v1 feature set. Still on the roadmap: the settings screen with the local/iCloud sync toggle (Phase 4), verification of the on-device AI capture on real devices (Phases 5.1/6.1/7.3), the production deployment of the density API (Phase 9.2), the client's density cache (Phase 10), and unit conversion — the volume/weight toggle on each recipe (Phase 11).

## CI & quality

GitHub Actions runs on every PR targeting `main` and every push to `main`: Swift build + test + coverage (iOS and macOS), .NET build + test, linting (SwiftLint/SwiftFormat, `dotnet format`), and a SonarCloud analysis with quality gate for the whole repo (the badges above). The project targets 90%+ test coverage on both sides.

## License

MIT — one [`LICENSE`](LICENSE) at the repo root covering the whole repository (`app/` + `api/`). See the [Licensing section of PLAN.md](PLAN.md#licensing) for the reasoning behind the choice.
