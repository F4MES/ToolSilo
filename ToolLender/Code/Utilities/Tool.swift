import Foundation

// Model for et værktøj
struct Tool: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageURL: String?
    let ownerUID: String
    let pricePerDay: Double?
    let category: String
    var isOnHold: Bool
    var timestamp: Date?
}
