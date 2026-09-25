import Foundation

/// Cleans up words the on-device model puts in the wrong ingredient field (issue #76): it
/// uses descriptors as units ("1 large egg" → unit "large") and wording in the schema or
/// instructions doesn't stop it, so the mapping filters them out itself.
enum IngredientDescriptors {
    /// Measurement units in the languages the app ships in (en, es, fr, de, nl), lowercased.
    /// Plurals are matched by `isMeasurementUnit` stripping a trailing "s", "es" or "n".
    private static let measurementUnits: Set<String> = [
        // English
        "cup", "c", "tablespoon", "tbsp", "tbs", "tbl", "teaspoon", "tsp", "t",
        "gram", "g", "kilogram", "kg", "milligram", "mg", "ounce", "oz", "fl oz", "fluid ounce",
        "pound", "lb", "milliliter", "millilitre", "ml", "centiliter", "centilitre", "cl",
        "deciliter", "decilitre", "dl", "liter", "litre", "l", "pint", "pt", "quart", "qt",
        "gallon", "gal", "pinch", "dash", "drop", "clove", "can", "tin", "jar", "bottle",
        "package", "pkg", "packet", "bag", "box", "envelope", "stick", "slice", "sprig",
        "bunch", "handful", "head", "stalk",
        // Spanish
        "cucharada", "cda", "cucharadita", "cdta", "cdita", "taza", "pizca", "diente", "lata",
        "rebanada", "manojo", "sobre", "gramo", "kilo", "litro", "mililitro",
        // French
        "cuillère à soupe", "cuillères à soupe", "c. à s.", "càs", "cs", "cuillère à café",
        "cuillères à café", "c. à c.", "càc", "cc", "tasse", "pincée", "gousse", "boîte",
        "tranche", "botte", "sachet", "verre", "gramme", "litre",
        // German
        "el", "tl", "esslöffel", "teelöffel", "tasse", "prise", "msp", "messerspitze", "bund",
        "dose", "päckchen", "pck", "scheibe", "zehe", "becher", "zweig",
        // Dutch
        "eetlepel", "theelepel", "kopje", "snufje", "teen", "teentje", "blik", "plak", "bosje",
        "zakje", "takje",
    ]

    /// Size words dropped from the front of a name, so "large yellow onion" reads "yellow
    /// onion". Colour and variety words stay: "brown sugar" and "green onion" are different
    /// ingredients from sugar and onion.
    private static let sizeWords: Set<String> = [
        "large", "medium", "small", "extra-large", "jumbo",
    ]

    /// Placeholders the model writes instead of leaving a field empty.
    static func isPlaceholder(_ text: String) -> Bool {
        ["none", "n/a", "na", "-"].contains(text.lowercased())
    }

    static func isMeasurementUnit(_ text: String) -> Bool {
        var unit = text.lowercased()
        if unit.hasSuffix("."), !measurementUnits.contains(unit) {
            unit.removeLast()
        }
        if measurementUnits.contains(unit) {
            return true
        }
        return ["es", "s", "n"].contains { suffix in
            unit.hasSuffix(suffix) && measurementUnits.contains(String(unit.dropLast(suffix.count)))
        }
    }

    static func removingSizeWords(from name: String) -> String {
        var words = name.split(separator: " ")
        while let first = words.first, words.count > 1, sizeWords.contains(first.lowercased()) {
            words.removeFirst()
        }
        return words.joined(separator: " ")
    }

    /// The longest run of up to three words at the start of `text` that is a measurement unit,
    /// so "cuillères à soupe de sucre" gives "cuillères à soupe".
    static func leadingUnit(in text: String) -> String? {
        let words = text.split(whereSeparator: \.isWhitespace)
        for count in stride(from: min(3, words.count), through: 1, by: -1) {
            let candidate = words.prefix(count).joined(separator: " ")
            if isMeasurementUnit(candidate) {
                return candidate
            }
        }
        return nil
    }

    /// The longest run of up to three words at the end of `text` that is a measurement unit,
    /// so "a pinch" gives "pinch".
    static func trailingUnit(in text: String) -> String? {
        let words = text.split(whereSeparator: \.isWhitespace)
        for count in stride(from: min(3, words.count), through: 1, by: -1) {
            let candidate = words.suffix(count).joined(separator: " ")
            if isMeasurementUnit(candidate) {
                return candidate
            }
        }
        return nil
    }

    /// Whether the ingredient line or its name occurs in `source` as whole words, ignoring case,
    /// accents and spacing. The model occasionally adds an ingredient that isn't in the recipe
    /// ("eau" in a crêpe recipe that never mentions water).
    static func appears(in source: String, rawText: String, name: String) -> Bool {
        let haystack = folded(source)
        return [rawText, name].contains { candidate in
            let needle = folded(candidate)
            guard !needle.isEmpty else { return false }
            let pattern = "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: needle) + "(?![\\p{L}\\p{N}])"
            return haystack.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
