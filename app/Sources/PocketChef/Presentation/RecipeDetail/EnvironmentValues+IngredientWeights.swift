import SwiftUI

extension EnvironmentValues {
    /// Converts ingredient lines to grams for the recipe's weight view (Phase 11). Set at the
    /// app's root; nil in previews and tests, where the weight view has nothing to convert.
    @Entry var convertIngredientsToWeight: (any ConvertIngredientsToWeightUseCase)?
}
