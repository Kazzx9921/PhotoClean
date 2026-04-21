import Foundation

enum PhotoDecision: String, Codable, Sendable {
    case pending
    case kept
    case trashed
}

enum UndoAction: Equatable {
    case trashed(id: String, fileSize: Int64?)
    case kept(id: String)
}
