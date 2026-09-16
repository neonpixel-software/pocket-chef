import Foundation

protocol FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag
}

final class DefaultFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    private let repository: TagRepository

    init(repository: TagRepository) {
        self.repository = repository
    }

    func execute(name: String) throws -> Tag {
        try repository.findOrCreate(name: name)
    }
}
