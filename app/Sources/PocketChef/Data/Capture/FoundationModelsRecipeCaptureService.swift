import Foundation
import FoundationModels

/// The only place FoundationModels is imported — kept isolated to the Data layer per
/// Clean Architecture. NOT unit tested: there's no way to run the on-device model in this
/// environment, matching PLAN.md's own note that real-device checks are manual/
/// semi-automated, not strict pass-fail units. CapturedRecipeSchema's toDomain() mapping
/// (the pure-Swift part of this pipeline) is tested independently.
final class FoundationModelsRecipeCaptureService: RecipeCaptureService {
    func isAvailable() -> Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    func captureRecipe(from text: String) async throws -> Recipe {
        let session = LanguageModelSession(instructions: {
            "Extract this recipe into a structured title, ingredient lines, equipment, and " +
                "steps. Preserve the ingredient's exact original wording in rawText even when " +
                "you also identify amount/unit/name. Put tools and cookware such as pans or " +
                "skewers in equipment, not ingredients."
        })
        do {
            // Greedy sampling: with the default sampling the model sometimes writes garbled
            // quantities ("1±³" for "1 1/2") that no parser can recover (issue #76).
            // Xcode 27 (Swift 6.4) deprecates `sampling:` for `samplingMode:`, which GitHub CI's
            // Xcode 26 SDK doesn't have, so pick by toolchain. Drop the #else once CI moves to 27.
            #if compiler(>=6.4)
            let options = GenerationOptions(samplingMode: .greedy)
            #else
            let options = GenerationOptions(sampling: .greedy)
            #endif
            let result = try await session.respond(
                to: text,
                generating: CapturedRecipeSchema.self,
                options: options
            )
            return result.content.toDomain(source: text)
        } catch {
            // Preserve the original error (guardrail rejection, model unavailable, schema
            // mismatch, etc.) so on-device verification can distinguish failure causes rather
            // than seeing only a generic "capture failed".
            throw RecipeCaptureError.captureFailed(underlying: error)
        }
    }
}
