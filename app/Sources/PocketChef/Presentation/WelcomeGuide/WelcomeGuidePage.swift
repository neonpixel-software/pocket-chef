import Foundation

/// One page of the welcome guide: plain data, so the tests can read the text without a view.
struct WelcomeGuidePage: Identifiable, Equatable {
    enum Topic: Hashable {
        case welcome, addRecipe, cook, settings
    }

    let id: Topic
    let systemImage: String
    let title: String
    let body: String
    /// Short points under the body, such as the three ways to add a recipe.
    var items: [String] = []
    /// A closing remark in smaller type.
    var note: String?

    /// What VoiceOver reads for the page, which is one element: all its text, then where it is
    /// ("Page 2 of 4"). The position goes in the label, not the value: the Mac doesn't read a
    /// value on a group. A comma follows only text that doesn't end in punctuation already, so
    /// VoiceOver doesn't read "yourself., Page 2 of 4".
    func accessibilityLabel(at index: Int, of count: Int) -> String {
        let parts = [title, body] + items + [note].compactMap(\.self) + [String(localized: "Page \(index + 1) of \(count)")]
        return parts.dropFirst().reduce(parts[0]) { label, part in
            label + (label.last?.isPunctuation == true ? " " : ", ") + part
        }
    }

    /// The guide's four pages. Page 2 only offers the ways to add a recipe this device has:
    /// Type It and Paste a Link need Apple Intelligence (the same check as the + menu).
    static func pages(isCaptureAvailable: Bool) -> [WelcomeGuidePage] {
        [
            WelcomeGuidePage(
                id: .welcome,
                systemImage: "fork.knife",
                title: String(localized: "Welcome to Pocket Chef"),
                body: String(localized: "A recipe box without the fluff: no ads, no life stories, just the recipe. Here's a quick tour.")
            ),
            isCaptureAvailable ? addRecipeWithCapture : addRecipeByHand,
            WelcomeGuidePage(
                id: .cook,
                systemImage: "frying.pan",
                title: String(localized: "Cook From It"),
                body: String(localized: "Open a recipe for a clean page with just the ingredients and steps."),
                items: [
                    String(localized: "Photos and tags: add them when you edit a recipe, and filter your list by tag."),
                    String(localized: "Weight: switch the ingredients from As Written to Weight to see them in grams."),
                ]
            ),
            WelcomeGuidePage(
                id: .settings,
                systemImage: "gearshape",
                title: String(localized: "Make It Yours"),
                body: String(localized: "In Settings you can change:"),
                items: [
                    String(localized: "Storage: keep your recipes on this device, or sync them with iCloud."),
                    String(localized: "Cups and Spoons: US or metric sizes, used for weights."),
                    String(localized: "Ingredient Densities: they update daily, and you can refresh them any time."),
                ],
                note: settingsLocation
            ),
        ]
    }

    private static var addRecipeWithCapture: WelcomeGuidePage {
        WelcomeGuidePage(
            id: .addRecipe,
            systemImage: "plus",
            title: String(localized: "Add a Recipe"),
            body: String(localized: "Choose + and then one of three ways:"),
            items: [
                String(localized: "Type It: type or paste a recipe's text."),
                String(localized: "Paste a Link: the address of a recipe's web page."),
                String(localized: "Enter Manually: fill in the recipe yourself."),
            ],
            note: String(localized: "For Type It and Paste a Link, Apple Intelligence reads the recipe on your device. You always check it before it's saved.")
        )
    }

    private static var addRecipeByHand: WelcomeGuidePage {
        WelcomeGuidePage(
            id: .addRecipe,
            systemImage: "plus",
            title: String(localized: "Add a Recipe"),
            body: String(localized: "Choose + and then Enter Manually to fill in a recipe yourself."),
            note: String(localized: "Type It and Paste a Link read a recipe for you with Apple Intelligence, which isn't available on this device.")
        )
    }

    /// Where Settings is, which differs per platform, and that the guide can be opened again.
    private static var settingsLocation: String {
        #if os(macOS)
        String(localized: "Settings is in the Pocket Chef menu (⌘,). You can open this guide again there, or from the Help menu.")
        #else
        String(localized: "Settings is the gear at the top of your recipes. You can open this guide again there too.")
        #endif
    }
}
