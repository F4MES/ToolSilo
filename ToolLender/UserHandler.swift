import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Håndterer kald og logik for brugere i Firestore.
class UserHandler {
    static let shared = UserHandler()

    private init() {}

    // MARK: - Hent Brugerdata
    /// Henter hele brugerens Firestore-dokument som en dictionary ([String: Any]).
    private func fetchUserData(userUID: String) async throws -> [String: Any]? {
        let db = Firestore.firestore()
        let document = try await db.collection("users").document(userUID).getDocument()
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
        let db = Firestore.firestore()
        try await db.collection("users").document(userUID).updateData(updates)
    }

    // MARK: - Slet Bruger
    /// Sletter brugeren fra Firestore og FirebaseAuth, hvis brugeren er den aktive.
    /// (Hvis du også vil slette brugerens værktøjer, kan du evt. kalde ToolHandler.shared.deleteTool(...) for hver af brugerens tools før dette.)
    func deleteUser(userUID: String) async throws {
        let db = Firestore.firestore()
        // Slet Firestore-dokumentet for brugeren
        try await db.collection("users").document(userUID).delete()

        // Slet fra FirebaseAuth, hvis den nuværende bruger er den samme
        guard let currentUser = Auth.auth().currentUser, currentUser.uid == userUID else { return }
        try await currentUser.delete()
    }
} 
