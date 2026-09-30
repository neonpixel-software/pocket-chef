import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        #if os(macOS)
        form
            .frame(width: 440)
            .fixedSize(horizontal: false, vertical: true)
        #else
        NavigationStack {
            form
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        #endif
    }

    private var form: some View {
        Form {
            Section {
                Picker("Store Recipes", selection: storageModeBinding) {
                    Text("On This Device").tag(StorageMode.local)
                    Text("iCloud").tag(StorageMode.iCloud)
                }
                .pickerStyle(.inline)
                .disabled(!viewModel.canChangeStorage)

                if viewModel.isSwitching {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Moving your recipes…")
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Storage")
            } footer: {
                Text(footerText)
            }
        }
        .formStyle(.grouped)
    }

    private var footerText: LocalizedStringKey {
        if !viewModel.isICloudAvailableInBuild {
            return "iCloud sync isn't available in this build."
        }
        return "With iCloud, your recipes sync to your other devices signed in to the same account. Switching back to this device keeps a copy of every recipe here and stops syncing."
    }

    private var storageModeBinding: Binding<StorageMode> {
        Binding(
            get: { viewModel.storageMode },
            set: { mode in Task { await viewModel.selectStorageMode(mode) } }
        )
    }
}
