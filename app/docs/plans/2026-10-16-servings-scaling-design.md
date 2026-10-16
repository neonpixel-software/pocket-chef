# Phase 15: Servings and scaling — design

Source: `PLAN.md` Phase 15 (added 2026-10-16, after the 1.0.1 release).

Goal: a recipe knows how many servings it makes, and the recipe screen can
show it for more or fewer servings, with the ingredient amounts changed to
match.

## Scope decisions (user, 2026-10-16)

- **Scaling is temporary.** The +/− control changes only what the recipe
  screen shows. Reopening the recipe shows it at its own number of servings
  again. The saved recipe never changes, so rounding can't add up and nothing
  extra syncs.
- **Kitchen-friendly amounts.** Scaled amounts are rounded to what you can
  measure, and the original line stays visible under each scaled one.
- **No servings set: prompt.** A recipe without a number shows a "Set
  servings" button that opens Edit. The +/− control appears once it has one.
- **A yield counts as servings.** "12 muffins" or "1 loaf" is 12 or 1
  servings: scaling works by a factor either way. The label is "Servings" in
  every language; no separate "Makes".

Settled with them: scaling applies in the Weight view too, and steps and
equipment aren't scaled (rewriting free text is risky).

## Data

- `Recipe.servings: Int?`, nil when unknown, 1–99.
- `RecipeModel.servings: Int?`, an optional field, so it syncs through
  CloudKit and recipes saved before it existed (or by an older app version)
  read as nil.
- The new field must be deployed to the production CloudKit schema before the
  build that ships it reaches TestFlight (`app/docs/rollout.md`).

## Form

A "Servings" row in the form's first section, with the title: a stepper from
1 to 99 and a "Not set" state that can be cleared back to. New recipes start
unset unless capture found a number.

## Capture

- `CapturedRecipeSchema` gets a `servings` field: "How many people or servings
  the recipe makes, as a whole number, if stated, else empty."
- Like ingredients, the number is kept only when it appears in the source
  text, so the model can't invent one. A range ("4–6") takes the lower number.
  Anything that isn't a whole number from 1 to 99 is dropped.
- URL capture: `RecipeStructuredData` passes the JSON-LD `recipeYield` into
  the text the model reads, so it's there to pick up.

## Scaling

- The recipe screen keeps the shown number in its view model, starting at
  the recipe's number on every open. Factor = shown ÷ recipe's number.
- `IngredientLine.scaled(by:)` returns a copy with the amount multiplied and
  the text rewritten:
  - When the amount as written is at the start of `rawText` ("⅔ cup flour",
    "1 1/2 tbsp", "2.5 dl"), only that part is replaced.
  - Otherwise the line is built from amount, unit and name.
  - A line without an amount ("salt to taste", "a pinch") is unchanged.
- Rounding (shown amount only):
  - Cups and spoons: nearest ¼ or ⅓ (⅛ below 1 for spoons), as fractions.
  - Metric units: whole numbers, tens above 100.
  - Ounces, pounds, pints and the like: one decimal.
  - Counted items (no unit, or a unit without a fixed size): nearest ½.
  - A non-zero amount never rounds to 0; it shows the smallest step instead.
- The Weight view converts the scaled lines, so grams follow. Grams come from
  the exact scaled amount, not the rounded one.
- Known limit: units keep their singular or plural form as written ("1 cup"
  → "2 cup"). Plurals in five languages can come later if it bothers.

## Recipe screen

- Above the ingredients: `Servings  [−] 4 [+]`. When the shown number differs
  from the recipe's, "(recipe: 2)" and a reset button appear.
- Scaled lines show the scaled text, with the original line under it in the
  small grey style the Weight view uses. At the recipe's own number nothing
  extra shows.
- No number: a "Set servings" button that opens Edit.

## Testing

- Unit:
  - `IngredientLine.scaled(by:)`: replacing the amount in the text (whole,
    decimal, "½", "1 1/2"), building the line when the amount isn't in the
    text, unchanged lines without an amount, each rounding rule, never 0.
  - Capture: "Serves 4", "4–6 personen", "12 muffins"; a number not in the
    source is dropped; empty stays nil.
  - Storage: servings round-trips; a recipe without the field loads as nil.
  - Detail view model and view: +/− within 1–99, reset, "(recipe: N)" only
    when changed, the "Set servings" prompt, scaled grams in the Weight view.
  - Form: setting, changing and clearing servings.
- UI: a recipe for 2, + twice, "⅔ cup flour" reads "1⅓ cup flour".
- Strings: "Servings", "Set servings", "(recipe: %lld)" and the reset label in
  the five languages, with a native-speaker check.
- On device: capture the miljuschka.nl banana bread and a French recipe,
  check the servings, scale in As Written and Weight, check iCloud sync
  between the iPhone and the Mac.

## Delivery

Three PRs:

1. Model, storage and form (15.1).
2. Capture (15.2).
3. Scaling and the recipe screen (15.3).
