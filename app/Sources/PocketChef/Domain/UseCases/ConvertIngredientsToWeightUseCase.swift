import Foundation

@MainActor
protocol ConvertIngredientsToWeightUseCase {
    /// Each line's weight in grams, or why it has none, keyed by line id. Reads only the
    /// cached densities, so it works offline.
    func execute(_ lines: [IngredientLine]) -> [UUID: IngredientWeight]
}

@MainActor
final class DefaultConvertIngredientsToWeightUseCase: ConvertIngredientsToWeightUseCase {
    private let cacheRepository: DensityCacheRepository
    private let standard: VolumeStandard

    init(cacheRepository: DensityCacheRepository, standard: VolumeStandard = .current) {
        self.cacheRepository = cacheRepository
        self.standard = standard
    }

    func execute(_ lines: [IngredientLine]) -> [UUID: IngredientWeight] {
        let entries: [DensityEntry]
        do {
            entries = try cacheRepository.allEntries()
        } catch {
            print("Reading the density cache failed: \(error)")
            entries = []
        }
        let index = DensityNameIndex(entries)
        var weights: [UUID: IngredientWeight] = [:]
        for line in lines {
            let density = line.ingredientName.flatMap(index.entry(forIngredientNamed:))
            weights[line.id] = IngredientWeight.of(line, density: density, standard: standard)
        }
        return weights
    }
}

/// Finds a recipe's ingredient among the cached entries. Strict on purpose (PLAN.md: no
/// guessing): it forgives only spelling differences that can't change the ingredient, which
/// are case, Unicode form, surrounding spaces, a hyphen written as a space ("all purpose
/// flour") and a plural ending ("walnut" → "walnuts"). "Unsalted butter" doesn't match "butter".
struct DensityNameIndex {
    private var entries: [String: DensityEntry] = [:]

    init(_ entries: [DensityEntry]) {
        for entry in entries {
            self.entries[Self.key(for: entry.ingredientName)] = entry
        }
    }

    func entry(forIngredientNamed name: String) -> DensityEntry? {
        let key = Self.key(for: name)
        guard !key.isEmpty else { return nil }
        var candidates = [key, key + "s", key + "es"]
        for suffix in ["es", "s"] where key.hasSuffix(suffix) {
            candidates.append(String(key.dropLast(suffix.count)))
        }
        return candidates.lazy.compactMap { entries[$0] }.first
    }

    private static func key(for name: String) -> String {
        DensityEntry.lookupKey(for: name)
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
