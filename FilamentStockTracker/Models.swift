import Foundation

enum MaterialType: String, CaseIterable, Codable, Identifiable {
    case pp = "PP"
    case tpu = "TPU"
    case pla = "PLA"
    case abs = "ABS"
    case petg = "PETG"

    var id: String { rawValue }
}

struct StockRow: Codable, Identifiable, Hashable {
    // Firestore docID'yi material yapacağız
    var id: String { material }
    let material: String
    let quantity: Int
}

struct LogRow: Codable, Identifiable, Hashable {
    // Firestore docID string
    let id: String

    // createdAt her log için app tarafından yazılacak ama güvenli olsun
    let created_at: Date?

    let material: String
    let delta: Int
    let reason: String?
    let user_email: String?
}

