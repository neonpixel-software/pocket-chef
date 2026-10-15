import SwiftUI

/// An inline error under a form or capture field: the text in the primary text color, with a
/// pink warning icon. Pink text on the background is too faint to read (2.97:1, under the
/// 4.5:1 WCAG AA minimum), so the pink only marks the message as an error.
struct PCErrorMessage: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Label {
            Text(message)
                .foregroundStyle(PCColor.textPrimary)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(PCColor.pink)
        }
        .font(PCFont.body(13))
    }
}
