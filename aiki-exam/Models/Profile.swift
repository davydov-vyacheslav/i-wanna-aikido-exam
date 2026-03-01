import Foundation
import SwiftData

@Model
final class Profile {

    // MARK: – Stored properties

    @Attribute(.unique) var id: UUID
    var name: String
    /// JSON-encoded [TechnicItem]. Using a Data blob avoids
    /// a separate @Model relationship for a simple value list.
    var technicsData: Data
    var createdAt: Date
    var isPreset: Bool

    // MARK: – Computed helpers

    var technics: [TechnicItem] {
        get {
            (try? JSONDecoder().decode([TechnicItem].self, from: technicsData)) ?? []
        }
        set {
            technicsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    // MARK: – Init

    init(
        id: UUID = UUID(),
        name: String,
        technics: [TechnicItem] = [],
        createdAt: Date = .now,
        isPreset: Bool = false
    ) {
        self.id = id
        self.name = name
        self.technicsData = (try? JSONEncoder().encode(technics)) ?? Data()
        self.createdAt = createdAt
        self.isPreset = isPreset
    }

    // MARK: – Factory helpers

    /// Clone with a new id and custom name.
    func clone(name: String) -> Profile {
        Profile(name: name, technics: technics, isPreset: false)
    }

}
