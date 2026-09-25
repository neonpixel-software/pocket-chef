@testable import PocketChef
import XCTest

final class HTMLContentReducerTests: XCTestCase {
    func testRemovesNonContentElements() {
        let html = """
        <body><header>Logo</header><nav><a>Home</a></nav>
        <svg><style>.logo{fill:#131920}</style></svg><script>track()</script>
        <p>Mix the batter.</p>
        <aside>Related recipes</aside><form>Newsletter</form><footer>© Site</footer></body>
        """

        let reduced = HTMLContentReducer.reduced(html)

        XCTAssertTrue(reduced.contains("<p>Mix the batter.</p>"))
        for noise in ["Logo", "Home", "fill:#131920", "track()", "Related recipes", "Newsletter", "© Site"] {
            XCTAssertFalse(reduced.contains(noise), "still contains \(noise)")
        }
    }

    func testRemovalIsCaseInsensitiveAndSpansLines() {
        let html = "<NAV class=\"menu\">\nHome\nRecipes\n</NAV><p>Keep</p><Script type=\"text/javascript\">\nx()\n</Script>"

        XCTAssertEqual(HTMLContentReducer.reduced(html), "<p>Keep</p>")
    }

    func testPrefersMainElementWhenPresent() {
        let html = "<body><div>Sidebar promo</div><main id=\"content\"><h1>Soup</h1></main><div>More promo</div></body>"

        XCTAssertEqual(HTMLContentReducer.reduced(html), "<h1>Soup</h1>")
    }

    func testFallsBackToArticleWhenThereIsNoMain() {
        let html = "<body><div>Promo</div><article class=\"recipe\"><h1>Soup</h1></article></body>"

        XCTAssertEqual(HTMLContentReducer.reduced(html), "<h1>Soup</h1>")
    }

    func testKeepsHeaderInsideMainSinceItOftenHoldsTheRecipeTitle() {
        let html = "<header>Site logo</header><main><header><h1>Soup</h1></header><nav>Jump to recipe</nav><p>Simmer.</p></main>"

        XCTAssertEqual(HTMLContentReducer.reduced(html), "<header><h1>Soup</h1></header><p>Simmer.</p>")
    }

    func testKeepsWholeDocumentWhenNeitherMainNorArticleExists() {
        let html = "<body><h1>Soup</h1><p>Simmer.</p></body>"

        XCTAssertEqual(HTMLContentReducer.reduced(html), html)
    }

    func testDoesNotMistakeLookalikeTagsForRemovableOnes() {
        // <header> must not match <head>, <navigation-bar> must not match <nav>, <mainline> not <main>.
        let html = "<head><title>T</title></head><navigation-bar>Keep me</navigation-bar><mainline>Also keep</mainline>"

        XCTAssertEqual(HTMLContentReducer.reduced(html), html)
    }
}
