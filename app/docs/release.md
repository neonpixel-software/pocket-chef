# Release builds

Pocket Chef ships through the App Store only, on iOS, iPadOS and macOS. So there's no Developer ID
signing and no notarization: App Store Connect signs and checks what it distributes. Xcode Cloud
does the build. Pushing a `vX.Y.Z` tag is the one step that archives the iOS and macOS apps and
uploads both to App Store Connect and TestFlight. Nothing for releases runs on a Mac, so no
signing certificates or App Store Connect keys are needed locally.

## Versions

- **Version** (`CFBundleShortVersionString`): `MARKETING_VERSION` in `app/project.yml`, one value
  for every platform.
- **Build number** (`CFBundleVersion`): Xcode Cloud sets it on every build, counting up across
  all of the product's workflows. `CURRENT_PROJECT_VERSION` in `project.yml` only applies to
  local builds and stays `1`.
- **Tag**: `v` + `MARKETING_VERSION`, for example `v1.0.0`. `ci_scripts/ci_post_clone.sh` fails
  a tag build whose tag doesn't match, before anything is built.

## Cutting a release

1. Open a PR that sets `MARKETING_VERSION` to the new version, and merge it once CI passes.
2. Tag the merge commit on `main` and push the tag:
   ```sh
   git switch main && git pull
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Xcode Cloud's **Release** workflow builds both platforms. When it's green, both builds are in
   TestFlight for internal testers. From there, follow the 12.4 rollout.

If no build starts, check that the Release workflow was saved before the tag was pushed: Xcode
Cloud ignores tags pushed before the workflow existed. Start the build by hand with Xcode (⌘9 →
Cloud → right-click Release → Start Build…) and pick the tag.

If the build fails, fix the problem on `main`. Then either bump the version and use a new tag, or
delete the tag and push it again on the new commit (`git push origin :v1.0.0`) as long as no build
of that version was uploaded.

## One-time setup: the Release workflow

Set this up in Xcode (⌘9 → Cloud → right-click the product → Manage Workflows) or in App Store
Connect (Xcode Cloud → Manage Workflows). The existing TestFlight workflow stays as it is. Xcode
Cloud has one product for the app, named PocketChef-iOS after the scheme it was created from. iOS
and macOS share the bundle ID, so the macOS archive goes in the same product's workflow, and the
App Store Connect app record must list macOS as a platform.

| Setting | Value |
|---|---|
| Name | Release |
| Start condition | **Tag Changes**, custom tag pattern `v*`. Remove the default Branch Changes condition. Leave **Auto-cancel builds** off. |
| Environment | The same Xcode and macOS as the existing workflow. Secret environment variables: `DEVELOPMENT_TEAM`, `DENSITY_API_HOST`, `DENSITY_API_READ_KEY` (see `ci_post_clone.sh`). |
| Action 1 | **Archive**, platform iOS, scheme `PocketChef-iOS`, deployment preparation **TestFlight and App Store** |
| Action 2 | **Archive**, platform macOS, scheme `PocketChef-macOS`, deployment preparation **TestFlight and App Store** |
| Post-actions | **TestFlight Internal Testing** for each archive, to the internal group |

Before the first release, check that:
- **Signing:** Xcode Cloud signs with cloud-managed certificates. The App Store archives get the
  production iCloud environment, which needs the CloudKit schema deployed to production in the
  CloudKit console (PLAN 12.4).
- **Upload keys:** `project.yml` sets `ITSAppUsesNonExemptEncryption = NO`, since the app only
  uses HTTPS, which is exempt. It also sets the Mac category (`LSApplicationCategoryType`, Food &
  Drink), which a Mac App Store upload requires.
