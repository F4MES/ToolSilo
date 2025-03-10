import FirebaseFirestore
import Foundation

/// Håndterer håndtering af ejerforeninger med Firestore offline persistence
class AssociationHandler {
    static let shared = AssociationHandler()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Henter alle ejerforeninger med caching og offline support
    func fetchAssociations(insertAllAtTop: Bool = true, useCache: Bool = true) async throws -> [String] {
        if useCache {
            // Check først om der er data i cachen
            let cachedSnapshot = try? await Firestore.firestore().collection("associations")
                .getDocuments(source: .cache)
            
            // Hvis vi har cache data, brug det og opdater i baggrunden
            if let documents = cachedSnapshot?.documents, !documents.isEmpty {
                // Start baggrundsopdatering
                Task {
                    _ = try? await Firestore.firestore().collection("associations")
                        .getDocuments(source: .server)
                    print("cache opdateret (associations)")
                }
                
                var associations = documents.compactMap { $0["name"] as? String }
                if insertAllAtTop {
                    associations.insert("All", at: 0)
                }
                return associations
            }
        }
        
        // Hvis ingen cache eller cache er tom, hent fra server
        let snapshot = try await Firestore.firestore().collection("associations")
            .getDocuments(source: .server)
        
        var associations = snapshot.documents.compactMap { $0["name"] as? String }
        if insertAllAtTop {
            associations.insert("All", at: 0)
        }
        return associations
    }
    
    // MARK: - Create Operations
    func addAssociation(name: String) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let snapshot = try await Firestore.firestore().collection("associations")
            .whereField("name", isEqualTo: trimmedName)
            .getDocuments()
        
        guard snapshot.isEmpty else {
            throw AssociationError.associationExists
        }
        
        try await Firestore.firestore().collection("associations").addDocument(data: [
            "name": trimmedName,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Private Helpers
    
    func updateUserAssociation(userUID: String, newAssociation: String) async throws {
        let userRef = Firestore.firestore().collection("users").document(userUID)
        try await userRef.setData(["association": newAssociation], merge: true)
    }
    
}

// MARK: - Error Handling
extension AssociationHandler {
    enum AssociationError: LocalizedError {
        case firestoreError(Error)
        case emptyResult
        case associationExists
        
        var errorDescription: String? {
            switch self {
            case .firestoreError(let error):
                return "Firestore fejl: \(error.localizedDescription)"
            case .emptyResult:
                return "Ingen foreninger fundet"
            case .associationExists:
                return "Association already exists"
            }
        }
    }
} 
