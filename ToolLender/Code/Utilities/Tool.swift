import Foundation

// Model for et værktøj
struct Tool: Identifiable, Codable {
    let id: String // Unikt ID for værktøjet
    let name: String // Navn på værktøjet
    let description: String // Beskrivelse af værktøjet
    let imageURL: String? // URL til værktøjets billede
    let ownerUID: String // UID for værktøjets ejer
    let pricePerDay: Double? // Pris per dag for at leje værktøjet
    let category: String // Ejerforeningens navn
    var isOnHold: Bool // tracker op et item er ledigt eller ej
    var timestamp: Date? // tidspunkt for oprettelse
}
