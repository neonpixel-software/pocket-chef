import Foundation

/// Fallback for pages without recipe JSON-LD (see RecipeStructuredData): trims the HTML down to
/// its likely content before it is flattened to text, so the capped text handed to the model is
/// the recipe rather than site navigation (issue #74). Regex-based on purpose — it only needs to
/// drop obvious noise, not parse HTML faithfully; anything it misses is still just extra text.
enum HTMLContentReducer {
    /// Never content, wherever they appear.
    private static let noiseElements = ["script", "style", "noscript", "template", "svg", "iframe", "nav", "aside", "form"]
    /// Page chrome at document level, but inside `<main>`/`<article>` a `<header>` often holds the
    /// recipe title, so these are only removed when no content container was found.
    private static let pageChromeElements = ["header", "footer"]

    static func reduced(_ html: String) -> String {
        let withoutNoise = removingElements(noiseElements, from: html)
        if let content = innerHTML(of: "main", in: withoutNoise) ?? innerHTML(of: "article", in: withoutNoise) {
            return content
        }
        return removingElements(pageChromeElements, from: withoutNoise)
    }

    private static func removingElements(_ tags: [String], from html: String) -> String {
        let names = tags.joined(separator: "|")
        let pattern = #"<(\#(names))\#(tagNameEnd)[^>]*>.*?</\1\s*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return html
        }
        return regex.stringByReplacingMatches(in: html, range: NSRange(html.startIndex..., in: html), withTemplate: "")
    }

    /// Stops e.g. <header> matching "head", or <navigation-bar>/<nav-menu> matching "nav".
    private static let tagNameEnd = #"(?=[\s/>])"#

    private static func innerHTML(of tag: String, in html: String) -> String? {
        let pattern = #"<\#(tag)\#(tagNameEnd)[^>]*>(.*?)</\#(tag)\s*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }
}
