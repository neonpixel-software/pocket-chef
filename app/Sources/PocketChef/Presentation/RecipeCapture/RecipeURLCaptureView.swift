import SwiftUI

struct RecipeURLCaptureView: View {
    /// Example placeholder text for the URL field, not a real endpoint.
    private static let urlFieldPlaceholder = "https://example.com/recipe"

    /// Owned as @State: the list builds the view model inside a `.sheet` closure, which runs
    /// again whenever the list re-renders. With @Bindable the sheet switched to that new view
    /// model and lost the pasted link and any fetch in progress (#89).
    @State private var viewModel: RecipeURLCaptureViewModel
    @Environment(\.dismiss) private var dismiss
    let onCaptured: (Recipe) -> Void

    init(viewModel: RecipeURLCaptureViewModel, onCaptured: @escaping (Recipe) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onCaptured = onCaptured
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paste a recipe link below. AI pulls out the title, ingredients, and steps for you to review before saving.")
                    .font(PCFont.body(14))
                    .foregroundStyle(PCColor.textPrimary.opacity(0.7))

                TextField(Self.urlFieldPlaceholder, text: $viewModel.urlText)
                    .font(PCFont.body(15))
                    .foregroundStyle(PCColor.textPrimary)
                    .padding(16)
                    .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 14))
                    .disabled(viewModel.isCapturing)
                    #if !os(macOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(PCFont.body(13))
                        .foregroundStyle(PCColor.pink)
                }

                Spacer()
            }
            .padding(20)
            .background(PCColor.background)
            .navigationTitle("Paste a Link")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isCapturing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isCapturing {
                        ProgressView()
                    } else {
                        Button("Capture") {
                            Task {
                                if let recipe = await viewModel.capture() {
                                    onCaptured(recipe)
                                }
                            }
                        }
                        .disabled(!viewModel.canCapture)
                    }
                }
            }
        }
        .tint(PCColor.pink)
    }
}

#Preview {
    PCFontRegistrar.registerCustomFonts()
    return RecipeURLCaptureView(
        viewModel: RecipeURLCaptureViewModel(
            captureRecipeFromURLUseCase: DefaultCaptureRecipeFromURLUseCase(
                webPageFetcher: PreviewWebPageFetcher(),
                captureRecipeUseCase: DefaultCaptureRecipeUseCase(captureService: PreviewRecipeCaptureService())
            )
        ),
        onCaptured: { _ in }
    )
}
