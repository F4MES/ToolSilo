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
        if useCache {
            // Check først om der er data i cachen
            let cachedSnapshot = try? await Firestore.firestore().collection("tools")
                .order(by: "timestamp", descending: true)
                .getDocuments(source: .cache)
            
            // Hvis vi har cache data, brug det og opdater i baggrunden
            if let documents = cachedSnapshot?.documents, !documents.isEmpty {
                // Start baggrundsopdatering
                Task {
                    _ = try? await Firestore.firestore().collection("tools")
                        .order(by: "timestamp", descending: true)
                        .getDocuments(source: .server)
                    print("cache opdateret (tools)")
                }
                
                return documents.map { doc in
                    let data = doc.data()
                    return Tool(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        imageURL: data["imageURL"] as? String,
                        ownerUID: data["ownerUID"] as? String ?? "",
                        pricePerDay: data["pricePerDay"] as? Double,
                        category: data["category"] as? String ?? "",
                        isOnHold: data["isOnHold"] as? Bool ?? false,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue()
                    )
                }
            }
        }
        
        // Hvis ingen cache eller cache er tom, hent fra server
        let snapshot = try await Firestore.firestore().collection("tools")
            .order(by: "timestamp", descending: true)
            .getDocuments(source: .server)
        
        return snapshot.documents.map { doc in
            let data = doc.data()
            return Tool(
                id: doc.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                imageURL: data["imageURL"] as? String,
                ownerUID: data["ownerUID"] as? String ?? "",
                pricePerDay: data["pricePerDay"] as? Double,
                category: data["category"] as? String ?? "",
                isOnHold: data["isOnHold"] as? Bool ?? false,
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue()
            )
        }
    }

    /// Henter værktøjer fra Firestore, hvor feltet "ownerUID" matcher den angivne UID.
    func fetchToolsByOwner(ownerUID: String, useCache: Bool = true) async throws -> [Tool] {
        if useCache {
            // Check først om der er data i cachen
            let cachedSnapshot = try? await Firestore.firestore().collection("tools")
                .whereField("ownerUID", isEqualTo: ownerUID)
                .getDocuments(source: .cache)
            
            // Hvis vi har cache data, brug det og opdater i baggrunden
            if let documents = cachedSnapshot?.documents, !documents.isEmpty {
                // Start baggrundsopdatering
                Task {
                    _ = try? await Firestore.firestore().collection("tools")
                        .whereField("ownerUID", isEqualTo: ownerUID)
                        .getDocuments(source: .server)
                    print("cache opdateret (tools by owner)")
                }
                
                return documents.map { doc in
                    let data = doc.data()
                    return Tool(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "Name not available",
                        description: data["description"] as? String ?? "Description not available",
                        imageURL: data["imageURL"] as? String,
                        ownerUID: data["ownerUID"] as? String ?? "Owner UID not available",
                        pricePerDay: data["pricePerDay"] as? Double,
                        category: data["category"] as? String ?? "Category not available",
                        isOnHold: data["isOnHold"] as? Bool ?? false,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue()
                    )
                }
            }
        }
        
        // Hvis ingen cache eller cache er tom, hent fra server
        let snapshot = try await Firestore.firestore().collection("tools")
            .whereField("ownerUID", isEqualTo: ownerUID)
            .getDocuments(source: .server)
        
        return snapshot.documents.map { doc in
            let data = doc.data()
            return Tool(
                id: doc.documentID,
                name: data["name"] as? String ?? "Name not available",
                description: data["description"] as? String ?? "Description not available",
                imageURL: data["imageURL"] as? String,
                ownerUID: data["ownerUID"] as? String ?? "Owner UID not available",
                pricePerDay: data["pricePerDay"] as? Double,
                category: data["category"] as? String ?? "Category not available",
                isOnHold: data["isOnHold"] as? Bool ?? false,
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue()
            )
        }
    }

    // MARK: - Opdater
    /// Toggler 'isOnHold' for det angivne værktøj i Firestore.
    func toggleHoldStatus(for tool: Tool) async throws {
        try await Firestore.firestore().collection("tools")
            .document(tool.id)
            .updateData(["isOnHold": !tool.isOnHold])
    }

    // MARK: - Slet
    /// Sletter et specifikt værktøj i Firestore.
    func deleteTool(_ tool: Tool) async throws {
        try await Firestore.firestore().collection("tools")
            .document(tool.id)
            .delete()
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





    // Ikke brugt - for nu
    /// Henter et specifikt værktøj fra Firestore
    func fetchTool(documentID: String, useCache: Bool = true) async throws -> Tool {
        if useCache {
            // Check først om der er data i cachen
            let cachedDoc = try? await Firestore.firestore().collection("tools")
                .document(documentID)
                .getDocument(source: .cache)
            
            if let data = cachedDoc?.data() {
                return Tool(
                    id: documentID,
                    name: data["name"] as? String ?? "Name not available",
                    description: data["description"] as? String ?? "Description not available",
                    imageURL: data["imageURL"] as? String,
                    ownerUID: data["ownerUID"] as? String ?? "Owner UID not available",
                    pricePerDay: data["pricePerDay"] as? Double,
                    category: data["category"] as? String ?? "Category not available",
                    isOnHold: data["isOnHold"] as? Bool ?? false,
                    timestamp: data["timestamp"] as? Date
                )
            }
        }
        
        // Hvis ingen cache eller cache er tom, hent fra server
        let document = try await Firestore.firestore()
            .collection("tools")
            .document(documentID)
            .getDocument(source: .server)
        
        guard let data = document.data() else {
            throw NSError(domain: "ToolError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document data not found"])
        }
        
        // Data fra serveren bliver automatisk gemt i cachen til næste gang
        return Tool(
            id: documentID,
            name: data["name"] as? String ?? "Name not available",
            description: data["description"] as? String ?? "Description not available",
            imageURL: data["imageURL"] as? String,
            ownerUID: data["ownerUID"] as? String ?? "Owner UID not available",
            pricePerDay: data["pricePerDay"] as? Double,
            category: data["category"] as? String ?? "Category not available",
            isOnHold: data["isOnHold"] as? Bool ?? false,
            timestamp: data["timestamp"] as? Date
        )
    }
}
