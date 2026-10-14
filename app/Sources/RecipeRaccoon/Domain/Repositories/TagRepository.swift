import Foundation

protocol TagRepository {
    func fetchAll() throws -> [Tag]
    func findOrCreate(name: String) throws -> Tag
}
