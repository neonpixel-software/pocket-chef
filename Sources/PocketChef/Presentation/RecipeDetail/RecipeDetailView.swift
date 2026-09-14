import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        List {
            Section("Ingredients") {
                if recipe.ingredients.isEmpty {
                    Text("No ingredients listed")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recipe.ingredients) { ingredient in
                        Text(ingredient.rawText)
                    }
                }
            }
            Section("Steps") {
                if recipe.steps.isEmpty {
                    Text("No steps listed")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                    }
                }
            }
        }
        .navigationTitle(recipe.title)
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: SampleData.recipes[0])
    }
}
