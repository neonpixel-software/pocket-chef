import Foundation

/// Shows a converted weight the way a kitchen scale reads: whole grams, with one decimal
/// below 10 g, where a gram is a big share ("5.7 g" salt).
enum IngredientWeightFormatter {
    static func format(grams: Double, locale: Locale = .current) -> String {
        let fractionDigits = grams < 10 ? 0...1 : 0...0
        // .asProvided keeps grams: the default usage would show ounces in a US locale.
        return Measurement(value: grams, unit: UnitMass.grams).formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(fractionDigits))
            )
            .locale(locale)
        )
    }
}
