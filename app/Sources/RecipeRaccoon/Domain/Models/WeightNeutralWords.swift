import Foundation

/// Words in an ingredient name that don't change what a cup or spoon of it weighs, in the
/// languages the app ships in: temperature and state ("softened", "zachte", "fondu"), "unsalted"
/// (the butter entry is unsalted butter) and oil and extract grades ("extra virgin", "pure").
///
/// The density lookup drops them only after the exact name finds nothing, so "zachte boter"
/// finds "boter" and "butter, softened" finds "butter". Words that do change what a cup holds
/// aren't here and keep a name from matching: sifted, packed, chopped, and fresh or whole,
/// which name other ingredients (fresh breadcrumbs, whole peppercorns). "Salted" isn't here
/// either: salted butter is a different product from the unsalted entry.
enum WeightNeutralWords {
    /// German adjectives take an ending that follows the noun's gender and case.
    private static let germanStems = [
        "weich", "zerlassen", "geschmolzen", "flüssig", "kalt", "lauwarm", "warm", "zimmerwarm", "ungesalzen",
    ]

    /// Lower case with single spaces and hyphens written as spaces, like the lookup key.
    private static let phrases: [[Substring]] = {
        let english = [
            "softened", "soft", "melted", "cold", "chilled", "warm", "lukewarm", "room temperature",
            "at room temperature", "unsalted", "pure", "extra virgin", "organic", "freshly squeezed",
        ]
        let dutch = [
            "zacht", "zachte", "gesmolten", "koud", "koude", "lauw", "lauwe", "lauwwarm", "lauwwarme",
            "warm", "warme", "kamertemperatuur", "op kamertemperatuur", "ongezouten", "biologisch",
            "biologische", "extra vierge",
        ]
        let german = germanStems.flatMap { stem in ["", "e", "en", "er", "es"].map { stem + $0 } }
            + ["zimmertemperatur", "raumtemperatur", "bio"]
        let french = [
            "mou", "molle", "ramolli", "ramollie", "fondu", "fondue", "froid", "froide", "tiède",
            "à température ambiante", "pommade", "en pommade", "bio", "extra vierge",
        ]
        let spanish = [
            "blando", "blanda", "derretido", "derretida", "fundido", "fundida", "frío", "fría", "tibio",
            "tibia", "templado", "templada", "a temperatura ambiente", "sin sal", "pomada", "en pomada",
            "virgen extra", "extra virgen", "ecológico", "ecológica", "orgánico", "orgánica",
        ]
        let all = Set(english + dutch + german + french + spanish)
        // Longest first, so "at room temperature" goes as a whole before "room temperature".
        return all.map { $0.split(separator: " ") }.sorted { $0.count > $1.count }
    }()

    /// `key` without those words and without commas and brackets, or nil when that leaves it
    /// unchanged or empty. `key` is a lookup key: lower case, single spaces, no hyphens.
    static func removing(from key: String) -> String? {
        let words = key.split { $0.isWhitespace || ",()".contains($0) }
        var kept: [Substring] = []
        var index = 0
        while index < words.count {
            if let phrase = phrases.first(where: { words[index...].starts(with: $0) }) {
                index += phrase.count
            } else {
                kept.append(words[index])
                index += 1
            }
        }
        let reduced = kept.joined(separator: " ")
        return reduced.isEmpty || reduced == key ? nil : reduced
    }
}
