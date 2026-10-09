import SwiftUI

/// About Pocket Chef (14.2): why the app exists, that it's open source and doesn't track anyone,
/// links to its code and to reporting an issue, and the version. Pushed from Settings on iOS;
/// its own window on the Mac, from Pocket Chef → About Pocket Chef.
struct AboutView: View {
    /// The Mac's About window, which replaces the standard About panel: that panel only has room
    /// for the icon, the version and a credits file.
    static let windowID = "about"
    static let macSize = CGSize(width: 540, height: 760)

    let info: AboutInfo

    init(info: AboutInfo = AboutInfo()) {
        self.info = info
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(verbatim: "Pocket Chef")
                    .font(PCFont.display(34))
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)

                section("The Idea") {
                    paragraph("""
                    Recipe sites bury the recipe under ads, pop-ups and life stories. \
                    Pocket Chef keeps just the recipe: type it, paste it or link it, check it once, and cook from a clean page.
                    """)
                }

                section("Open Source") {
                    paragraph("Pocket Chef is open source under the MIT license. Anyone can read the code, check what the app does, and build it themselves.")
                }

                // This list has to stay literally true and complete: see "No tracking" in the
                // design doc, and check it against the code before each release.
                section("No Tracking") {
                    bullet("No account, no ads, no analytics, no tracking.")
                    bullet("Your recipes stay on this device, or in your own iCloud if you turn on sync.")
                    bullet("Recipe capture runs on your device.")
                    paragraph("The app only goes online to:")
                    bullet("Fetch the recipe from a link you paste. That website sees the visit, as it would in a browser.")
                    bullet("Sync your recipes through your own iCloud, if you turn it on.")
                    bullet("Download ingredient densities from Pocket Chef's server. The app sends it nothing about you or your recipes.")
                }

                links

                VStack(spacing: 4) {
                    Text(info.versionText)
                    Text("Made by NeonPixel")
                }
                .font(PCFont.body(13))
                .opacity(0.7)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
            .foregroundStyle(PCColor.textPrimary)
            .frame(maxWidth: 520, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(PCColor.background)
        #if os(iOS)
        .navigationTitle("About Pocket Chef")
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// Pink buttons with ink text, like the welcome guide's: pink text on cream is too faint.
    private var links: some View {
        VStack(spacing: 10) {
            Group {
                link("View the Code on GitHub", to: AboutInfo.repositoryURL)
                link("Report an Issue", to: AboutInfo.newIssueURL)
            }
            .buttonStyle(.borderedProminent)
            .tint(PCColor.pink)

            Text("Reporting an issue needs a free GitHub account.")
                .font(PCFont.body(13))
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    /// The text color goes on the label: the Mac's prominent style would make it white.
    private func link(_ title: LocalizedStringKey, to url: URL) -> some View {
        Link(destination: url) {
            Text(title)
                .font(PCFont.body(17, weight: .bold))
                .foregroundStyle(PCColor.onPink)
                .padding(.vertical, 4)
        }
    }

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(PCFont.display(22))
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func paragraph(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(PCFont.body(16))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bullet(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(PCColor.teal)
                .accessibilityHidden(true)
            Text(text)
                .font(PCFont.body(16))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if os(macOS)
/// Pocket Chef → About Pocket Chef, in place of the standard About panel.
struct AboutCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Pocket Chef") { openWindow(id: AboutView.windowID) }
        }
    }
}
#endif
