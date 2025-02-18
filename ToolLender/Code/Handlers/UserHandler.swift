import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Håndterer kald og logik for brugere i Firestore.
class UserHandler {
    static let shared = UserHandler()

    private init() {}

    // MARK: - Hent Brugerdata
    /// Henter hele brugerens Firestore-dokument som en dictionary ([String: Any]).
    func fetchUserData(userUID: String) async throws -> [String: Any]? {
        let document = try await Firestore.firestore().collection("users")
            .document(userUID)
            .getDocument(source: .cache) // Cache first
        
        return document.data()
    }

    /// Henter kun et brugernavn, hvis det findes.
    func fetchUserName(userUID: String) async throws -> String? {
        let data = try await fetchUserData(userUID: userUID)
        return data?["name"] as? String
    }

    /// Henter brugerens association. Returnerer "All", hvis feltet mangler.
    func fetchUserAssociation(userUID: String) async throws -> String {
        let data = try await fetchUserData(userUID: userUID)
        return data?["association"] as? String ?? "All"
    }

    // MARK: - Opdatering
    /// Opdaterer vilkårlige felter i "users" collection (fx ["address": "Ny adresse"]).
    func updateUserFields(userUID: String, updates: [String: Any]) async throws {
        guard !updates.isEmpty else { return }
        try await Firestore.firestore().collection("users")
            .document(userUID)
            .setData(updates, merge: true)
    }

    // MARK: - Slet Bruger
    /// Sletter brugeren fra Firestore og FirebaseAuth, hvis brugeren er den aktive.
    /// (Hvis du også vil slette brugerens værktøjer, kan du evt. kalde ToolHandler.shared.deleteTool(...) for hver af brugerens tools før dette.)
    func deleteUser(userUID: String) async throws {
        // Slet fra Firestore
        try await Firestore.firestore().collection("users").document(userUID).delete()
        
        // Slet fra Auth hvis samme bruger
        if let currentUser = Auth.auth().currentUser, currentUser.uid == userUID {
            try await currentUser.delete()
        }
    }
} 
