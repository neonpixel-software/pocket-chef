import Foundation

protocol FetchTagsUseCase {
    func execute() throws -> [Tag]
}

final class DefaultFetchTagsUseCase: FetchTagsUseCase {
    private let repository: TagRepository

    init(repository: TagRepository) {
        self.repository = repository
    }

    func execute() throws -> [Tag] {
        try repository.fetchAll()
    }
}
