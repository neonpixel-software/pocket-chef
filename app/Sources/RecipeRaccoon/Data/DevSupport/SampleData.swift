import Foundation

enum SampleData {
    static let recipes: [Recipe] = [
        Recipe(
            id: UUID(),
            title: "Pancakes",
            ingredients: [
                IngredientLine(id: UUID(), rawText: "2 cups flour", amount: 2, unit: "cup", ingredientName: "flour"),
                IngredientLine(id: UUID(), rawText: "1 cup milk", amount: 1, unit: "cup", ingredientName: "milk"),
                IngredientLine(id: UUID(), rawText: "1 egg"),
            ],
            steps: [
                "Mix dry ingredients",
                "Whisk in milk and egg",
                "Cook on a griddle until golden",
            ],
            source: .typed,
            tags: [Tag(id: UUID(), name: "Breakfast", isPreset: true)]
        ),
        Recipe(
            id: UUID(),
            title: "Tomato Soup",
            ingredients: [
                IngredientLine(id: UUID(), rawText: "4 large tomatoes", amount: 4, unit: nil, ingredientName: "tomato"),
                IngredientLine(id: UUID(), rawText: "1 onion, diced"),
            ],
            steps: [
                "Simmer tomatoes and onion until soft",
                "Blend until smooth",
                "Season to taste",
            ],
            source: .typed,
            tags: [Tag(id: UUID(), name: "Dinner", isPreset: true)]
        ),
    ]
}
