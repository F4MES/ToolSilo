import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Håndterer kald og logik for værktøjer i Firestore.
class ToolHandler {
    static let shared = ToolHandler()

    private init() {}

    // MARK: - Hent Værktøjer
    /// Henter alle værktøjer i 'tools' collection, evt. sorteret efter timestamp.
    func fetchAllTools(useCache: Bool = true) async throws -> [Tool] {
        let source: FirestoreSource = useCache ? .default : .server
        let snapshot = try await Firestore.firestore().collection("tools")
            .order(by: "timestamp", descending: true)
            .getDocuments(source: source)

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
    func fetchToolsByOwner(ownerUID: String, useCache: Bool = true) async throws -> [Tool] {
        let source: FirestoreSource = useCache ? .default : .server
        let snapshot = try await Firestore.firestore().collection("tools")
            .whereField("ownerUID", isEqualTo: ownerUID)
            .getDocuments(source: source)
        
        return try snapshot.documents.map { doc in
            let data = doc.data()
            return try decodeTool(from: data, documentID: doc.documentID)
        }
    }

    // MARK: - Opdater
    /// Toggler 'isOnHold' for det angivne værktøj i Firestore.
    func toggleHoldStatus(for tool: Tool, useCache: Bool = true) async throws {
        let db = Firestore.firestore()
        try await db.collection("tools").document(tool.id).updateData([
            "isOnHold": !tool.isOnHold
        ])
    }

    // MARK: - Slet
    /// Sletter et specifikt værktøj i Firestore.
    func deleteTool(_ tool: Tool) async throws {
        let db = Firestore.firestore()
        try await db.collection("tools").document(tool.id).delete()
    }

    // MARK: - Create Operations
    /// Uploader et nyt værktøj til Firestore
    func uploadTool(
        name: String,
        description: String,
        pricePerDay: Double,
        imageURL: String?,
        ownerUID: String,
        category: String
    ) async throws -> Tool {
        let toolRef = Firestore.firestore().collection("tools").document()
        
        let toolData: [String: Any] = [
            "id": toolRef.documentID,
            "name": name,
            "description": description,
            "pricePerDay": pricePerDay,
            "imageURL": imageURL ?? "",
            "ownerUID": ownerUID,
            "category": category,
            "isOnHold": false,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        try await toolRef.setData(toolData)
        return try await fetchTool(documentID: toolRef.documentID)
    }

    /// Henter et specifikt værktøj fra Firestore
    func fetchTool(documentID: String) async throws -> Tool {
        let document = try await Firestore.firestore()
            .collection("tools")
            .document(documentID)
            .getDocument()
        
        guard let data = document.data() else {
            throw NSError(domain: "ToolError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document data not found"])
        }
        
        return try decodeTool(from: data, documentID: documentID)
    }

    private func decodeTool(from data: [String: Any], documentID: String) throws -> Tool {
        guard 
            let name = data["name"] as? String,
            let description = data["description"] as? String,
            let ownerUID = data["ownerUID"] as? String,
            let category = data["category"] as? String
        else {
            throw NSError(
                domain: "ToolError", 
                code: 1, 
                userInfo: [NSLocalizedDescriptionKey: "Invalid tool data format"]
            )
        }
        
        return Tool(
            id: documentID,
            name: name,
            description: description,
            imageURL: data["imageURL"] as? String,
            ownerUID: ownerUID,
            pricePerDay: data["pricePerDay"] as? Double,
            category: category,
            isOnHold: data["isOnHold"] as? Bool ?? false,
            timestamp: data["timestamp"] as? Date
        )
    }
}
