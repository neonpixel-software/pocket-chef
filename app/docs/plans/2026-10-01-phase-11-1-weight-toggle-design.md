# Phase 11.1: Volume/weight toggle — design

Source: `PLAN.md` Phase 11.1 and "Unit conversion". Builds on the density cache
(Phase 10).

Acceptance (from PLAN.md): toggling shows correct gram values for ingredients
with density data.

## Scope decisions

- **As Written ↔ Weight** (user decision, 2026-10-01). The toggle on the recipe
  screen has two modes:
  - As Written shows each line exactly as stored.
  - Weight shows volume lines in grams, using the ingredient's cached density.
    Weight lines (oz, lb, kg) also become grams, by plain unit conversion
    without a density.

  It doesn't convert weights into volumes, which would need rules for picking
  a cup, tablespoon or teaspoon and for rounding to kitchen fractions.
- **Cup and spoon sizes are a user setting** (user decision, 2026-10-02,
  replacing a language-based rule). Settings → Measurements → Cups and Spoons
  offers two choices:
  - US Customary: a 236.6 ml cup, a 14.8 ml tablespoon, a 4.9 ml teaspoon,
    and US pints and fluid ounces.
  - Metric: 250/15/5 ml cups and spoons, with imperial pints and fluid ounces.

  Until the user picks one, it defaults from the device's region
  (`Locale.measurementSystem`), never the language. An English speaker in the
  UK or the Netherlands gets metric cups. The choice is stored in
  `UserDefaults` under `volumeStandard`, and the recipe screen reconverts
  when it changes. A bare "oz" is always a weight, and a fluid ounce is
  written "fl oz".
- **Units** are recognized in all five shipped languages (cup, taza, tasse,
  kopje; EL, cuillère à soupe, eetlepel; ...), ignoring case, accents, a
  trailing dot and plural endings. Count and vague units (clove, can, pinch)
  have no size and are never weighed.
- **Matching names is strict (no guessing).** A line's `ingredientName`
  matches a cached entry when they're the same name, ignoring case, Unicode
  form, surrounding spaces, a hyphen written as a space ("all purpose flour"),
  or a plural ending ("walnut" → "walnuts"). It never substitutes a related
  ingredient: "unsalted butter" doesn't match "butter". The seed data is
  English only, so recipes in other languages mostly won't match yet.
- **Lines that can't be weighed stay as written.** That covers lines with no
  amount, no sized unit, or no density. Phase 11.2 adds the "conversion not
  available" note to the no-density case.
- **Display:** a converted line shows its weight with the ingredient name
  ("264 g all-purpose flour") and the original line underneath, smaller, so
  the cook can see what was converted. Weights are whole grams, with one
  decimal below 10 g, in the locale's number format, always in grams (never
  re-converted to ounces).
- **The choice is remembered** across recipes and launches (`@AppStorage`).

## Components

- Domain:
  - `MeasurementUnits` and `VolumeStandard`: the unit table and sizes; the
    standard is the user's Settings choice (`VolumeStandard.storageKey`),
    defaulting from the region.
  - `IngredientWeight.of(_:density:standard:)`: the arithmetic, plus the
    reason when a line can't be weighed.
  - `DensityNameIndex`: the name matching.
  - `ConvertIngredientsToWeightUseCase`: reads all cached entries once per
    recipe. `DensityCacheRepository` gains `allEntries()`.
- Presentation:
  - `IngredientWeightFormatter`.
  - The toggle and rows in `RecipeDetailView`.
- The use case reaches the view through the SwiftUI environment
  (`\.convertIngredientsToWeight`), set at the app's root. That keeps it out of
  `RecipeDetailViewModel`'s already long initializer. Previews and tests get
  nil, and nothing converts.

## Verification

- Unit tests:
  - Units: US and metric sizes, other languages, plurals, oz vs fl oz, unsized
    units.
  - Arithmetic: 1 US cup of flour = 125 g with the USDA density.
  - Name matching, including the cases that must not match.
  - The use case against a real in-memory cache with seed densities.
  - The formatter (US locale stays in grams, decimal comma in German).
  - String catalog coverage.
- In the iOS simulator (metric region, English UI, so metric 250 ml cups), with
  the cache filled from the API's 72 seeds. These numbers were recorded before
  the setting existed, when the region decided; the setting's region default
  gives the same result. With US Customary chosen, the same recipe gives
  2 cups flour → 250 g and 1 cup milk → 244 g (PR #125).
  - 2 cups all-purpose flour → 264 g, ½ cup sugar → 106 g, 1 cup milk →
    258 g, 1 tsp salt → 6,2 g, 4 oz chocolate → 113 g.
  - Saffron (no density) and "2 eggs" stay as written.
  - As Written shows every line unchanged.
