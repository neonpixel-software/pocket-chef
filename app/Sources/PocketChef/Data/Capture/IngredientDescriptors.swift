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
}
