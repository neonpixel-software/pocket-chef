import Foundation

struct Tag: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var isPreset: Bool
}
