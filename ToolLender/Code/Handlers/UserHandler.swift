import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Håndterer kald og logik for brugere i Firestore.
class UserHandler {
    static let shared = UserHandler()

    private init() {}

    // MARK: - Hent Brugerdata
    /// Henter hele brugerens Firestore-dokument.
    func fetchUserData(userUID: String, useCache: Bool = true) async throws -> UserInfo {
        if useCache {
            // Check først om der er data i cachen
            do {
                let cachedDoc = try await Firestore.firestore().collection("users")
                    .document(userUID)
                    .getDocument(source: .cache)
                
                if let data = cachedDoc.data() {
                    // Start baggrundsopdatering hvis vi er online
                    Task {
                        _ = try? await Firestore.firestore().collection("users")
                            .document(userUID)
                            .getDocument(source: .server)
                        print("cache opdateret (users)")
                    }
                    
                    return UserInfo(
                        id: cachedDoc.documentID,
                        name: data["name"] as? String ?? "Bruger",
                        email: data["email"] as? String ?? "",
                        phoneNumber: data["phoneNumber"] as? String,
                        address: data["address"] as? String,
                        association: data["association"] as? String ?? "All"
                    )
                }
            } catch {
                print("Cache miss: \(error.localizedDescription)")
            }
        }
        
        // Prøv at hente fra server, men hvis offline returner en default UserInfo
        do {
            let document = try await Firestore.firestore().collection("users")
                .document(userUID)
                .getDocument(source: .server)
            
            let data = document.data() ?? [:]
            return UserInfo(
                id: document.documentID,
                name: data["name"] as? String ?? "Bruger",
                email: data["email"] as? String ?? "",
                phoneNumber: data["phoneNumber"] as? String,
                address: data["address"] as? String,
                association: data["association"] as? String ?? "All"
            )
        } catch {
            // Hvis offline eller anden fejl, returner default UserInfo
            print("Server error (muligvis offline): \(error.localizedDescription)")
            return UserInfo(
                id: userUID,
                name: "Bruger (offline)",
                email: "",
                phoneNumber: nil,
                address: nil,
                association: "All"
            )
        }
    }

    /// Henter kun et brugernavn, hvis det findes.
    func fetchUserName(userUID: String, useCache: Bool = true) async throws -> String {
        let userInfo = try await fetchUserData(userUID: userUID, useCache: useCache)
        return userInfo.name
    }

    /// Henter brugerens association. Returnerer "All", hvis feltet mangler.
    func fetchUserAssociation(userUID: String, useCache: Bool = true) async throws -> String {
        let userInfo = try await fetchUserData(userUID: userUID, useCache: useCache)
        return userInfo.association
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
