import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "Ingredients", accent: PCColor.teal) {
                    Group {
                        if recipe.ingredients.isEmpty {
                            Text("No ingredients listed")
                                .font(PCFont.body(15))
                                .foregroundStyle(PCColor.textPrimary.opacity(0.55))
                                .padding(16)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(PCColor.teal)
                                            .frame(width: 8, height: 8)
                                        Text(ingredient.rawText)
                                            .font(PCFont.body(15))
                                            .foregroundStyle(PCColor.textPrimary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)

                                    if index < recipe.ingredients.count - 1 {
                                        Divider().opacity(0.3)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                }

                section(title: "Steps", accent: PCColor.pink) {
                    if recipe.steps.isEmpty {
                        Text("No steps listed")
                            .font(PCFont.body(15))
                            .foregroundStyle(PCColor.textPrimary.opacity(0.55))
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(index + 1)")
                                        .font(PCFont.body(13, weight: .bold))
                                        .foregroundStyle(PCColor.ink)
                                        .frame(width: 26, height: 26)
                                        .background(PCColor.pink, in: Circle())
                                    Text(step)
                                        .font(PCFont.body(15))
                                        .foregroundStyle(PCColor.textPrimary)
                                        .padding(.top, 3)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(PCColor.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            PCHeader(title: recipe.title)
        }
        .navigationTitle("")
        .tint(PCColor.pink)
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent)
                    .frame(width: 11, height: 11)
                Text(title.uppercased())
                    .font(PCFont.body(13, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PCColor.textPrimary)
            }
            content()
        }
    }
}

#Preview {
    PCFontRegistrar.registerCustomFonts()
    return NavigationStack {
        RecipeDetailView(recipe: SampleData.recipes[0])
    }
}
