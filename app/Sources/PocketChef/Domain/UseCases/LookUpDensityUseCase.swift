import Foundation

@MainActor
protocol LookUpDensityUseCase {
    /// The cached entry for an ingredient name, or nil when there's none. Never touches the network.
    func execute(ingredientName: String) throws -> DensityEntry?
}

@MainActor
final class DefaultLookUpDensityUseCase: LookUpDensityUseCase {
    private let cacheRepository: DensityCacheRepository

    init(cacheRepository: DensityCacheRepository) {
        self.cacheRepository = cacheRepository
    }

    func execute(ingredientName: String) throws -> DensityEntry? {
        try cacheRepository.entry(forIngredientNamed: ingredientName)
    }
}
