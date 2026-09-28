namespace PocketChef.DensityApi.Application.Seeding;

/// Seed densities from USDA FoodData Central, SR Legacy (April 2018 CSV release), which is
/// public domain under CC0 1.0 (see PLAN.md Phase 9.1 and api/README.md).
///
/// Each row names the SR Legacy food and the portion it came from. Rows are picked by hand:
/// many staples only have qualified cup portions ("cup, packed" for brown sugar, "cup,
/// unsifted" for powdered sugar), so matching "cup" as a substring would pick the wrong one.
/// Names are what a recipe calls the ingredient, lower case, since Phase 10 matches recipe
/// ingredient names against them.
///
/// Where a food has several volume portions, the row uses a cup (the largest volume, so the
/// least rounding in the gram weight) in the form recipes usually mean: packed brown sugar,
/// unsifted powdered sugar, shredded cheese, chopped nuts. Foods without a cup portion use a
/// tablespoon or teaspoon. "flour" and "sugar" repeat the all-purpose and granulated rows,
/// because that's how many recipes name them. Cake flour is left out: its only portion
/// ("1 cup unsifted, dipped" = 137 g) is heavier than bread flour's.
public static class UsdaSeedData
{
    // Name, FDC ID, portion amount, portion modifier as FDC gives it, measure, grams.
    public static IReadOnlyList<DensitySeedRow> Rows { get; } =
    [
        // Flours, grains and starches
        new("all-purpose flour", 168894, 1, "cup", HouseholdMeasure.Cup, 125), // Wheat flour, white, all-purpose, enriched, bleached
        new("flour", 168894, 1, "cup", HouseholdMeasure.Cup, 125), // Wheat flour, white, all-purpose, enriched, bleached
        new("bread flour", 168896, 1, "cup", HouseholdMeasure.Cup, 137), // Wheat flour, white, bread, enriched
        new("whole wheat flour", 168893, 1, "cup", HouseholdMeasure.Cup, 120), // Wheat flour, whole-grain (Includes foods for USDA's Food Distribution Program)
        new("self-rising flour", 168895, 1, "cup", HouseholdMeasure.Cup, 125), // Wheat flour, white, all-purpose, self-rising, enriched
        new("cornstarch", 169698, 1, "cup", HouseholdMeasure.Cup, 128), // Cornstarch
        new("cornmeal", 169697, 1, "cup", HouseholdMeasure.Cup, 122), // Cornmeal, whole-grain, yellow
        new("rolled oats", 173904, 1, "cup", HouseholdMeasure.Cup, 81), // Cereals, oats, regular and quick, not fortified, dry
        new("white rice", 168877, 1, "cup", HouseholdMeasure.Cup, 185), // Rice, white, long-grain, regular, raw, enriched
        new("quinoa", 168874, 1, "cup", HouseholdMeasure.Cup, 170), // Quinoa, uncooked
        new("breadcrumbs", 174928, 1, "cup", HouseholdMeasure.Cup, 108), // Bread, crumbs, dry, grated, plain

        // Sugars and syrups
        new("granulated sugar", 169655, 1, "cup", HouseholdMeasure.Cup, 200), // Sugars, granulated
        new("sugar", 169655, 1, "cup", HouseholdMeasure.Cup, 200), // Sugars, granulated
        new("brown sugar", 168833, 1, "cup packed", HouseholdMeasure.Cup, 220), // Sugars, brown
        new("powdered sugar", 169656, 1, "cup unsifted", HouseholdMeasure.Cup, 120), // Sugars, powdered
        new("honey", 169640, 1, "cup", HouseholdMeasure.Cup, 339), // Honey
        new("maple syrup", 169661, 1, "cup", HouseholdMeasure.Cup, 315), // Syrups, maple
        new("molasses", 168820, 1, "cup", HouseholdMeasure.Cup, 337), // Molasses
        new("corn syrup", 168837, 1, "cup", HouseholdMeasure.Cup, 341), // Syrups, corn, light

        // Fats and oils
        new("butter", 173430, 1, "cup", HouseholdMeasure.Cup, 227), // Butter, without salt
        new("vegetable oil", 172370, 1, "cup", HouseholdMeasure.Cup, 218), // Oil, vegetable, soybean, refined
        new("olive oil", 171413, 1, "cup", HouseholdMeasure.Cup, 216), // Oil, olive, salad or cooking
        new("canola oil", 172336, 1, "cup", HouseholdMeasure.Cup, 218), // Oil, canola
        new("coconut oil", 171412, 1, "cup", HouseholdMeasure.Cup, 218), // Oil, coconut
        new("sesame oil", 171016, 1, "cup", HouseholdMeasure.Cup, 218), // Oil, sesame, salad or cooking
        new("vegetable shortening", 173584, 1, "cup", HouseholdMeasure.Cup, 205), // Shortening, vegetable, household, composite
        new("lard", 171401, 1, "cup", HouseholdMeasure.Cup, 205), // Lard

        // Dairy
        new("milk", 171265, 1, "cup", HouseholdMeasure.Cup, 244), // Milk, whole, 3.25% milkfat, with added vitamin D
        new("buttermilk", 170874, 1, "cup", HouseholdMeasure.Cup, 245), // Milk, buttermilk, fluid, cultured, lowfat
        new("heavy cream", 170859, 1, "cup, fluid (yields 2 cups whipped)", HouseholdMeasure.Cup, 238), // Cream, fluid, heavy whipping
        new("half and half", 171255, 1, "cup", HouseholdMeasure.Cup, 242), // Cream, fluid, half and half
        new("sour cream", 171257, 1, "cup", HouseholdMeasure.Cup, 230), // Cream, sour, cultured
        new("plain yogurt", 171284, 1, "cup (8 fl oz)", HouseholdMeasure.Cup, 245), // Yogurt, plain, whole milk
        new("cream cheese", 173418, 1, "cup", HouseholdMeasure.Cup, 232), // Cheese, cream
        new("grated parmesan", 171247, 1, "cup", HouseholdMeasure.Cup, 100), // Cheese, parmesan, grated
        new("shredded cheddar", 173414, 1, "cup, shredded", HouseholdMeasure.Cup, 113), // Cheese, cheddar (Includes foods for USDA's Food Distribution Program)
        new("shredded mozzarella", 170845, 1, "cup, shredded", HouseholdMeasure.Cup, 112), // Cheese, mozzarella, whole milk

        // Leaveners, spices and flavorings
        new("salt", 173468, 1, "cup", HouseholdMeasure.Cup, 292), // Salt, table
        new("baking soda", 175040, 1, "tsp", HouseholdMeasure.Teaspoon, 4.6), // Leavening agents, baking soda
        new("baking powder", 172803, 1, "tsp", HouseholdMeasure.Teaspoon, 4.6), // Leavening agents, baking powder, double-acting, sodium aluminum sulfate
        new("cream of tartar", 175041, 1, "tsp", HouseholdMeasure.Teaspoon, 3), // Leavening agents, cream of tartar
        new("active dry yeast", 175043, 1, "tbsp", HouseholdMeasure.Tablespoon, 12), // Leavening agents, yeast, baker's, active dry
        new("cocoa powder", 169593, 1, "cup", HouseholdMeasure.Cup, 86), // Cocoa, dry powder, unsweetened
        new("ground cinnamon", 171320, 1, "tbsp", HouseholdMeasure.Tablespoon, 7.8), // Spices, cinnamon, ground
        new("ground ginger", 170926, 1, "tbsp", HouseholdMeasure.Tablespoon, 5.2), // Spices, ginger, ground
        new("ground nutmeg", 171326, 1, "tbsp", HouseholdMeasure.Tablespoon, 7), // Spices, nutmeg, ground
        new("black pepper", 170931, 1, "tbsp, ground", HouseholdMeasure.Tablespoon, 6.9), // Spices, pepper, black
        new("chili powder", 171319, 1, "tbsp", HouseholdMeasure.Tablespoon, 8), // Spices, chili powder
        new("paprika", 171329, 1, "tbsp", HouseholdMeasure.Tablespoon, 6.8), // Spices, paprika
        new("garlic powder", 171325, 1, "tbsp", HouseholdMeasure.Tablespoon, 9.7), // Spices, garlic powder
        new("onion powder", 171327, 1, "tbsp", HouseholdMeasure.Tablespoon, 6.9), // Spices, onion powder
        new("vanilla extract", 173471, 1, "cup", HouseholdMeasure.Cup, 208), // Vanilla extract

        // Liquids and condiments
        new("water", 174158, 1, "cup", HouseholdMeasure.Cup, 237), // Water, bottled, generic
        new("lemon juice", 167747, 1, "cup", HouseholdMeasure.Cup, 244), // Lemon juice, raw
        new("lime juice", 168156, 1, "cup", HouseholdMeasure.Cup, 242), // Lime juice, raw
        new("soy sauce", 174277, 1, "cup", HouseholdMeasure.Cup, 255), // Soy sauce made from soy and wheat (shoyu)
        new("white vinegar", 172237, 1, "cup", HouseholdMeasure.Cup, 238), // Vinegar, distilled
        new("apple cider vinegar", 173469, 1, "cup", HouseholdMeasure.Cup, 239), // Vinegar, cider
        new("balsamic vinegar", 172241, 1, "cup", HouseholdMeasure.Cup, 255), // Vinegar, balsamic
        new("red wine vinegar", 172240, 1, "cup", HouseholdMeasure.Cup, 239), // Vinegar, red wine
        new("mayonnaise", 171009, 1, "cup", HouseholdMeasure.Cup, 220), // Salad dressing, mayonnaise, regular
        new("ketchup", 168556, 1, "cup", HouseholdMeasure.Cup, 240), // Catsup
        new("yellow mustard", 172234, 1, "cup", HouseholdMeasure.Cup, 249), // Mustard, prepared, yellow
        new("coconut milk", 170173, 1, "cup", HouseholdMeasure.Cup, 226), // Nuts, coconut milk, canned (liquid expressed from grated meat and water)
        new("peanut butter", 172470, 1, "cup", HouseholdMeasure.Cup, 258), // Peanut butter, smooth style, without salt

        // Mix-ins, nuts and seeds
        new("chocolate chips", 167976, 1, "cup chips (6 oz package)", HouseholdMeasure.Cup, 168), // Candies, semisweet chocolate
        new("raisins", 168165, 1, "cup (not packed)", HouseholdMeasure.Cup, 145), // Raisins, dark, seedless (Includes foods for USDA's Food Distribution Program)
        new("walnuts", 170187, 1, "cup, chopped", HouseholdMeasure.Cup, 117), // Nuts, walnuts, english
        new("pecans", 170182, 1, "cup, chopped", HouseholdMeasure.Cup, 109), // Nuts, pecans
        new("sliced almonds", 170567, 1, "cup, sliced", HouseholdMeasure.Cup, 92), // Nuts, almonds
        new("shredded coconut", 168586, 1, "cup, shredded", HouseholdMeasure.Cup, 93), // Nuts, coconut meat, dried (desiccated), sweetened, shredded
        new("sesame seeds", 170150, 1, "cup", HouseholdMeasure.Cup, 144), // Seeds, sesame seeds, whole, dried
    ];
}
