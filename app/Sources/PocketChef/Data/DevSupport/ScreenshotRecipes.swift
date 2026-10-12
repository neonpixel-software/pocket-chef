#if DEBUG
import Foundation

/// The recipes of the App Store screenshots (UITestScenario.screenshots, PLAN.md 12.2), in the
/// app's five languages. Each has a stock photo from Wikimedia Commons (CC0 or public domain;
/// credits in app/docs/screenshots.md), bundled in Debug builds only.
///
/// The screenshots show every recipe's title, and the full recipe of the pancakes (the detail
/// screen) and the cookies (the weight view). Those two have their content in each language; the
/// others keep their English ingredients and steps, which no screenshot shows. The cookies'
/// weights only show in the English set: the density table names ingredients in English, so a
/// recipe written in another language has no weights to show (see ScreenshotRecipes.densities).
struct ScreenshotRecipe {
    struct Content {
        var title: String
        var ingredients: [IngredientLine] = []
        var equipment: [String] = []
        var steps: [String] = []
    }

    /// The photo's resource name in ScreenshotPhotos/ (`screenshot-<photo>.jpg`).
    let photo: String
    /// Preset tag names (Tag.presetNames).
    let tags: [String]
    /// English, the fallback for a missing language or field.
    let english: Content
    /// By language code (es, fr, de, nl).
    var translations: [String: Content] = [:]

    /// The recipe in `language`: its title, and its ingredients, equipment and steps where translated.
    func content(in language: String) -> Content {
        guard let translation = translations[language] else { return english }
        return Content(
            title: translation.title,
            ingredients: translation.ingredients.isEmpty ? english.ingredients : translation.ingredients,
            equipment: translation.equipment.isEmpty ? english.equipment : translation.equipment,
            steps: translation.steps.isEmpty ? english.steps : translation.steps
        )
    }
}

/// An ingredient line, its amount, unit and name as capture would split them.
private func line(_ rawText: String, _ amount: Double? = nil, _ unit: String? = nil, _ name: String? = nil) -> IngredientLine {
    IngredientLine(id: UUID(), rawText: rawText, amount: amount, unit: unit, ingredientName: name)
}

enum ScreenshotRecipes {
    /// The recipe the detail screenshot opens.
    static let detailRecipe = pancakes
    /// The recipe the weight screenshot opens.
    static let weightRecipe = cookies

    static let all = [pancakes, cookies, shakshuka, spaghetti, greekSalad, bananaBread]

    /// The density API's entries (2026-10-12) for the cookies' ingredients, so the weight view
    /// shows what the shipped app does. Grams per milliliter.
    static let densities: [String: Double] = [
        "all-purpose flour": 0.528,
        "baking soda": 0.933,
        "salt": 1.234,
        "butter": 0.959,
        "granulated sugar": 0.845,
        "brown sugar": 0.930,
        "vanilla extract": 0.879,
        "chocolate chips": 0.710,
    ]

    static let pancakes = ScreenshotRecipe(
        photo: "pancakes",
        tags: ["Breakfast"],
        english: .init(
            title: "Fluffy Pancakes",
            ingredients: [
                line("1 1/2 cups all-purpose flour", 1.5, "cup", "all-purpose flour"),
                line("2 tbsp sugar", 2, "tbsp", "sugar"),
                line("2 tsp baking powder", 2, "tsp", "baking powder"),
                line("1/2 tsp salt", 0.5, "tsp", "salt"),
                line("1 1/4 cups milk", 1.25, "cup", "milk"),
                line("1 egg", 1, nil, "egg"),
                line("3 tbsp butter, melted", 3, "tbsp", "butter"),
                line("Honey and walnuts, to serve", nil, nil, "honey"),
            ],
            equipment: ["Mixing bowl", "Whisk", "Griddle"],
            steps: [
                "Whisk the flour, sugar, baking powder and salt in a large bowl.",
                "Beat the milk, egg and melted butter together, then stir them into the dry ingredients until just combined.",
                "Heat a lightly oiled griddle over medium heat and pour 1/4 cup of batter per pancake.",
                "Flip when bubbles form on top, and cook until golden.",
                "Stack them up and serve with honey and walnuts.",
            ]
        ),
        translations: [
            "es": .init(
                title: "Tortitas esponjosas",
                ingredients: [
                    line("1 1/2 tazas de harina de trigo", 1.5, "taza", "harina de trigo"),
                    line("2 cucharadas de azúcar", 2, "cucharada", "azúcar"),
                    line("2 cucharaditas de levadura química", 2, "cucharadita", "levadura química"),
                    line("1/2 cucharadita de sal", 0.5, "cucharadita", "sal"),
                    line("1 1/4 tazas de leche", 1.25, "taza", "leche"),
                    line("1 huevo", 1, nil, "huevo"),
                    line("3 cucharadas de mantequilla derretida", 3, "cucharada", "mantequilla"),
                    line("Miel y nueces, para servir", nil, nil, "miel"),
                ],
                equipment: ["Bol", "Varillas", "Plancha"],
                steps: [
                    "Mezcla la harina, el azúcar, la levadura y la sal en un bol grande.",
                    "Bate la leche, el huevo y la mantequilla derretida, y añádelos a los ingredientes secos sin mezclar en exceso.",
                    "Calienta una plancha ligeramente engrasada a fuego medio y vierte 1/4 de taza de masa por tortita.",
                    "Dales la vuelta cuando salgan burbujas y cocínalas hasta que estén doradas.",
                    "Apílalas y sírvelas con miel y nueces.",
                ]
            ),
            "fr": .init(
                title: "Pancakes moelleux",
                ingredients: [
                    line("1 1/2 tasse de farine", 1.5, "tasse", "farine"),
                    line("2 c. à s. de sucre", 2, "c. à s.", "sucre"),
                    line("2 c. à c. de levure chimique", 2, "c. à c.", "levure chimique"),
                    line("1/2 c. à c. de sel", 0.5, "c. à c.", "sel"),
                    line("1 1/4 tasse de lait", 1.25, "tasse", "lait"),
                    line("1 œuf", 1, nil, "œuf"),
                    line("3 c. à s. de beurre fondu", 3, "c. à s.", "beurre"),
                    line("Miel et noix, pour servir", nil, nil, "miel"),
                ],
                equipment: ["Saladier", "Fouet", "Poêle à crêpes"],
                steps: [
                    "Mélangez la farine, le sucre, la levure et le sel dans un grand saladier.",
                    "Battez le lait, l’œuf et le beurre fondu, puis incorporez-les aux ingrédients secs sans trop mélanger.",
                    "Faites chauffer une poêle légèrement huilée à feu moyen et versez 1/4 de tasse de pâte par pancake.",
                    "Retournez-les dès que des bulles apparaissent et laissez-les dorer.",
                    "Empilez-les et servez avec du miel et des noix.",
                ]
            ),
            "de": .init(
                title: "Fluffige Pancakes",
                ingredients: [
                    line("1 1/2 Tassen Mehl", 1.5, "Tasse", "Mehl"),
                    line("2 EL Zucker", 2, "EL", "Zucker"),
                    line("2 TL Backpulver", 2, "TL", "Backpulver"),
                    line("1/2 TL Salz", 0.5, "TL", "Salz"),
                    line("1 1/4 Tassen Milch", 1.25, "Tasse", "Milch"),
                    line("1 Ei", 1, nil, "Ei"),
                    line("3 EL geschmolzene Butter", 3, "EL", "Butter"),
                    line("Honig und Walnüsse zum Servieren", nil, nil, "Honig"),
                ],
                equipment: ["Rührschüssel", "Schneebesen", "Pfanne"],
                steps: [
                    "Mehl, Zucker, Backpulver und Salz in einer großen Schüssel mischen.",
                    "Milch, Ei und geschmolzene Butter verquirlen und kurz unter die trockenen Zutaten rühren.",
                    "Eine leicht gefettete Pfanne bei mittlerer Hitze erhitzen und je Pancake 1/4 Tasse Teig hineingeben.",
                    "Wenden, sobald sich Bläschen bilden, und goldbraun backen.",
                    "Stapeln und mit Honig und Walnüssen servieren.",
                ]
            ),
            "nl": .init(
                title: "Luchtige pancakes",
                ingredients: [
                    line("1 1/2 kopje bloem", 1.5, "kopje", "bloem"),
                    line("2 el suiker", 2, "el", "suiker"),
                    line("2 tl bakpoeder", 2, "tl", "bakpoeder"),
                    line("1/2 tl zout", 0.5, "tl", "zout"),
                    line("1 1/4 kopje melk", 1.25, "kopje", "melk"),
                    line("1 ei", 1, nil, "ei"),
                    line("3 el gesmolten boter", 3, "el", "boter"),
                    line("Honing en walnoten, om te serveren", nil, nil, "honing"),
                ],
                equipment: ["Mengkom", "Garde", "Koekenpan"],
                steps: [
                    "Meng de bloem, suiker, bakpoeder en zout in een grote kom.",
                    "Klop de melk, het ei en de gesmolten boter los en roer dit kort door de droge ingrediënten.",
                    "Verhit een licht ingevette koekenpan op middelhoog vuur en schep per pancake 1/4 kopje beslag in de pan.",
                    "Keer ze om zodra er belletjes verschijnen en bak ze goudbruin.",
                    "Stapel ze op en serveer met honing en walnoten.",
                ]
            ),
        ]
    )

    static let cookies = ScreenshotRecipe(
        photo: "cookies",
        tags: ["Dessert", "Snack"],
        english: .init(
            title: "Chocolate Chip Cookies",
            ingredients: [
                line("2 1/4 cups all-purpose flour", 2.25, "cup", "all-purpose flour"),
                line("1 tsp baking soda", 1, "tsp", "baking soda"),
                line("1 tsp salt", 1, "tsp", "salt"),
                line("1 cup butter, softened", 1, "cup", "butter"),
                line("3/4 cup granulated sugar", 0.75, "cup", "granulated sugar"),
                line("3/4 cup brown sugar, packed", 0.75, "cup", "brown sugar"),
                line("2 large eggs", 2, nil, "eggs"),
                line("2 tsp vanilla extract", 2, "tsp", "vanilla extract"),
                line("2 cups chocolate chips", 2, "cup", "chocolate chips"),
            ],
            equipment: ["Stand mixer", "Baking sheets", "Parchment paper"],
            steps: [
                "Heat the oven to 375 °F (190 °C) and line two baking sheets with parchment.",
                "Whisk the flour, baking soda and salt together.",
                "Beat the butter and both sugars until creamy, then beat in the eggs and vanilla.",
                "Mix in the flour mixture, then fold in the chocolate chips.",
                "Drop rounded tablespoons of dough onto the sheets and bake for 9–11 minutes, until golden at the edges.",
            ]
        ),
        translations: [
            "es": .init(title: "Galletas con chispas de chocolate"),
            "fr": .init(title: "Cookies aux pépites de chocolat"),
            "de": .init(title: "Chocolate-Chip-Cookies"),
            "nl": .init(title: "Chocolate chip cookies"),
        ]
    )

    static let shakshuka = ScreenshotRecipe(
        photo: "shakshuka",
        tags: ["Breakfast", "Lunch"],
        english: .init(
            title: "Shakshuka",
            ingredients: [
                line("2 tbsp olive oil", 2, "tbsp", "olive oil"),
                line("1 onion, diced", 1, nil, "onion"),
                line("1 red bell pepper, diced", 1, nil, "red bell pepper"),
                line("3 cloves garlic, minced", 3, nil, "garlic"),
                line("1 tsp paprika", 1, "tsp", "paprika"),
                line("1 can (28 oz) crushed tomatoes", 1, nil, "crushed tomatoes"),
                line("6 eggs", 6, nil, "eggs"),
                line("Feta and parsley, to serve", nil, nil, "feta"),
            ],
            equipment: ["Large skillet with lid"],
            steps: [
                "Soften the onion and pepper in the olive oil, then add the garlic and paprika.",
                "Pour in the tomatoes and simmer for 10 minutes, until thickened.",
                "Make six wells in the sauce, crack in the eggs, cover and cook until the whites are set.",
                "Top with feta and parsley and serve with crusty bread.",
            ]
        ),
        translations: [
            "es": .init(title: "Shakshuka"),
            "fr": .init(title: "Chakchouka"),
            "de": .init(title: "Shakshuka"),
            "nl": .init(title: "Shakshuka"),
        ]
    )

    static let spaghetti = ScreenshotRecipe(
        photo: "spaghetti",
        tags: ["Dinner"],
        english: .init(
            title: "Spaghetti Marinara",
            ingredients: [
                line("1 lb spaghetti", 1, "lb", "spaghetti"),
                line("2 tbsp olive oil", 2, "tbsp", "olive oil"),
                line("4 cloves garlic, sliced", 4, nil, "garlic"),
                line("1 can (28 oz) crushed tomatoes", 1, nil, "crushed tomatoes"),
                line("1 tsp dried oregano", 1, "tsp", "dried oregano"),
                line("Grated parmesan, to serve", nil, nil, "grated parmesan"),
            ],
            equipment: ["Large pot", "Saucepan"],
            steps: [
                "Cook the spaghetti in plenty of salted water until al dente.",
                "Meanwhile, warm the garlic in the olive oil, add the tomatoes and oregano and simmer for 15 minutes.",
                "Toss the drained spaghetti with the sauce and top with parmesan.",
            ]
        ),
        translations: [
            "es": .init(title: "Espaguetis a la marinara"),
            "fr": .init(title: "Spaghetti à la sauce tomate"),
            "de": .init(title: "Spaghetti mit Tomatensoße"),
            "nl": .init(title: "Spaghetti marinara"),
        ]
    )

    static let greekSalad = ScreenshotRecipe(
        photo: "salad",
        tags: ["Lunch"],
        english: .init(
            title: "Greek Salad",
            ingredients: [
                line("1 head romaine lettuce, chopped", 1, nil, "romaine lettuce"),
                line("2 tomatoes, cut into wedges", 2, nil, "tomatoes"),
                line("1/2 red onion, thinly sliced", 0.5, nil, "red onion"),
                line("1/2 cup kalamata olives", 0.5, "cup", "kalamata olives"),
                line("7 oz feta, crumbled", 7, "oz", "feta"),
                line("3 tbsp olive oil", 3, "tbsp", "olive oil"),
            ],
            steps: [
                "Toss the lettuce, tomatoes, onion and olives in a large bowl.",
                "Scatter the feta on top and drizzle with olive oil.",
            ]
        ),
        translations: [
            "es": .init(title: "Ensalada griega"),
            "fr": .init(title: "Salade grecque"),
            "de": .init(title: "Griechischer Salat"),
            "nl": .init(title: "Griekse salade"),
        ]
    )

    static let bananaBread = ScreenshotRecipe(
        photo: "banana-bread",
        tags: ["Dessert", "Snack"],
        english: .init(
            title: "Chocolate Banana Bread",
            ingredients: [
                line("3 ripe bananas, mashed", 3, nil, "bananas"),
                line("1/3 cup butter, melted", 1.0 / 3, "cup", "butter"),
                line("3/4 cup brown sugar", 0.75, "cup", "brown sugar"),
                line("1 egg", 1, nil, "egg"),
                line("1 tsp baking soda", 1, "tsp", "baking soda"),
                line("1 1/4 cups all-purpose flour", 1.25, "cup", "all-purpose flour"),
                line("1/4 cup cocoa powder", 0.25, "cup", "cocoa powder"),
                line("1/2 cup chocolate chips", 0.5, "cup", "chocolate chips"),
            ],
            equipment: ["Loaf pan"],
            steps: [
                "Heat the oven to 350 °F (175 °C) and butter a loaf pan.",
                "Mix the bananas, butter, sugar and egg, then stir in the dry ingredients and the chocolate chips.",
                "Bake for 55–60 minutes, until a skewer comes out clean.",
            ]
        ),
        translations: [
            "es": .init(title: "Pan de plátano y chocolate"),
            "fr": .init(title: "Banana bread au chocolat"),
            "de": .init(title: "Schoko-Bananenbrot"),
            "nl": .init(title: "Bananenbrood met chocolade"),
        ]
    )
}
#endif
