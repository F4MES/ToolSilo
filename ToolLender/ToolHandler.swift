import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Håndterer kald og logik for værktøjer i Firestore.
class ToolHandler {
    static let shared = ToolHandler()

    private init() {}

    // MARK: - Hent Værktøjer
    /// Henter alle værktøjer i 'tools' collection, evt. sorteret efter timestamp.
    func fetchAllTools(descending: Bool = true) async throws -> [Tool] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("tools")
            .order(by: "timestamp", descending: descending)
            .getDocuments()

        return snapshot.documents.map { doc in
            Tool(
                id: doc.documentID,
                name: doc["name"] as? String ?? "",
                description: doc["description"] as? String ?? "",
                imageURL: doc["imageURL"] as? String,
                ownerUID: doc["ownerUID"] as? String ?? "Unknown",
                pricePerDay: doc["pricePerDay"] as? Double,
                category: doc["category"] as? String ?? "",
                isOnHold: doc["isOnHold"] as? Bool ?? false,
                timestamp: (doc["timestamp"] as? Timestamp)?.dateValue()
            )
        }
    }

    /// Henter værktøjer fra Firestore, hvor feltet "ownerUID" matcher den angivne UID.
    func fetchToolsByOwner(ownerUID: String) async throws -> [Tool] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("tools")
            .whereField("ownerUID", isEqualTo: ownerUID)
            .getDocuments()

        return snapshot.documents.map { doc in
            Tool(
                id: doc.documentID,
                name: doc["name"] as? String ?? "",
                description: doc["description"] as? String ?? "",
                imageURL: doc["imageURL"] as? String,
                ownerUID: doc["ownerUID"] as? String ?? "Unknown",
                pricePerDay: doc["pricePerDay"] as? Double,
                category: doc["category"] as? String ?? "",
                isOnHold: doc["isOnHold"] as? Bool ?? false,
                timestamp: (doc["timestamp"] as? Timestamp)?.dateValue()
            )
        }
    }

    // MARK: - Opdater
    /// Toggler 'isOnHold' for det angivne værktøj i Firestore.
    func toggleHoldStatus(for tool: Tool) async throws {
        let db = Firestore.firestore()
        let newStatus = !tool.isOnHold
        try await db.collection("tools").document(tool.id).updateData(["isOnHold": newStatus])
    }

    // MARK: - Slet
    /// Sletter et specifikt værktøj i Firestore.
    func deleteTool(_ tool: Tool) async throws {
        let db = Firestore.firestore()
        try await db.collection("tools").document(tool.id).delete()
    }

    /// Prøver at hente værktøjer online, gemmer i cache, men hvis det fejler, bruger vi cachens data.
    func fetchAllToolsCachedFirst() async -> [Tool] {
        do {
            let allTools = try await fetchAllTools(descending: true)
            LocalCacheManager.shared.saveTools(allTools)
            return allTools
        } catch {
            print("Failed to fetch from Firestore. Using cached tools if available. Error: \(error)")
            let cached = LocalCacheManager.shared.loadTools()
            return cached
        }
    }
} 