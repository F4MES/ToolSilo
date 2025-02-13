import FirebaseFirestore
import Foundation

/// Håndterer håndtering af ejerforeninger med Firestore offline persistence
class AssociationHandler {
    static let shared = AssociationHandler()
    private let db = Firestore.firestore()
    
    // MARK: - Public Methods
    
    /// Henter alle ejerforeninger med caching og offline support
     func fetchAssociations(insertAllAtTop: Bool) async throws -> [String] {
        let ref = Firestore.firestore().collection("associations")
        
        let source: FirestoreSource = FirestoreSource.cache
        let snapshot = try await ref.getDocuments(source: source)
        
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
        
        let snapshot = try await db.collection("associations")
            .whereField("name", isEqualTo: trimmedName)
            .getDocuments()
        
        guard snapshot.isEmpty else {
            throw AssociationError.associationExists
        }
        
        try await db.collection("associations").addDocument(data: [
            "name": trimmedName,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Private Helpers
    
    /// Bearbejder query snapshot og formaterer resultater
    private func processSnapshot(_ snapshot: QuerySnapshot, insertAllAtTop: Bool) -> [String] {
        var associations = snapshot.documents.compactMap { $0["name"] as? String }
        
        if insertAllAtTop && !associations.contains("All") {
            associations.insert("All", at: 0)
        }
        
        return associations
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
