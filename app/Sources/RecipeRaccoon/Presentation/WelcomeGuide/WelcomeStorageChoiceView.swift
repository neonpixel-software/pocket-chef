import SwiftUI

/// The welcome guide's choice between keeping recipes on this device and iCloud, under the last
/// page's text. It drives the same view model as Settings, so it switches at once and shows the
/// same progress and errors; On This Device is the default until the user picks iCloud.
struct WelcomeStorageChoiceView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("Where to Keep Your Recipes")
                .font(PCFont.body(17, weight: .semibold))
                .accessibilityAddTraits(.isHeader)

            Picker("Store Recipes", selection: storageModeBinding) {
                Text("On This Device").tag(StorageMode.local)
                Text("iCloud").tag(StorageMode.iCloud)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 320)
            .disabled(!viewModel.canChangeStorage)

            status
                .font(PCFont.body(14))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(PCColor.textPrimary)
    }

    @ViewBuilder private var status: some View {
        if viewModel.isSwitching {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Moving your recipes…")
            }
            .opacity(0.7)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        } else {
            Text(explanation)
                .opacity(0.7)
        }
    }

    private var explanation: LocalizedStringKey {
        if !viewModel.isICloudAvailableInBuild {
            return "iCloud sync isn't available in this build."
        }
        switch viewModel.storageMode {
        case .local:
            return "Your recipes stay on this device. You can turn on iCloud later in Settings."
        case .iCloud:
            return "Your recipes sync to your other devices signed in to the same account."
        }
    }

    private var storageModeBinding: Binding<StorageMode> {
        Binding(
            get: { viewModel.storageMode },
            set: { mode in Task { await viewModel.selectStorageMode(mode) } }
        )
    }
}
