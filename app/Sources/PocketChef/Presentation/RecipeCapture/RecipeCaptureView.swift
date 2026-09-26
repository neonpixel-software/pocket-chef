import SwiftUI

struct RecipeCaptureView: View {
    /// Owned as @State: the list builds the view model inside a `.sheet` closure, which runs
    /// again whenever the list re-renders. With @Bindable the sheet switched to that new view
    /// model and lost the typed text and any capture in progress (#89).
    @State private var viewModel: RecipeCaptureViewModel
    @Environment(\.dismiss) private var dismiss
    let onCaptured: (Recipe) -> Void

    init(viewModel: RecipeCaptureViewModel, onCaptured: @escaping (Recipe) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onCaptured = onCaptured
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paste or type a recipe below. AI pulls out the title, ingredients, and steps for you to review before saving.")
                        .font(PCFont.body(14))
                        .foregroundStyle(PCColor.textPrimary.opacity(0.7))

                    TextEditor(text: $viewModel.rawText)
                        .font(PCFont.body(15))
                        .foregroundStyle(PCColor.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 240)
                        .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 14))
                        .disabled(viewModel.isCapturing)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(PCFont.body(13))
                            .foregroundStyle(PCColor.pink)
                    }
                }
                .padding(20)
            }
            .background(PCColor.background)
            .navigationTitle("Type It")
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
    return RecipeCaptureView(
        viewModel: RecipeCaptureViewModel(
            captureRecipeUseCase: DefaultCaptureRecipeUseCase(captureService: PreviewRecipeCaptureService())
        ),
        onCaptured: { _ in }
    )
}
