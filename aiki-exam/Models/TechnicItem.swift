import Foundation

/// Immutable value type representing one exam technique triple.
/// Stored as JSON inside Profile.technicsData (SwiftData).
struct TechnicItem: Codable, Hashable, Equatable, Identifiable {
    let positionKey: String
    let attackKey: String
    let techniqueKey: String

    // Identifiable – stable synthetic id
    var id: String { "\(positionKey)|\(attackKey)|\(techniqueKey)" }
}

// TODO: extend me to return Master value (and cleanup in other places)
