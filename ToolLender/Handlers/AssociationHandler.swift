import FirebaseFirestore
import Foundation

/// Håndterer håndtering af ejerforeninger med Firestore offline persistence
class AssociationHandler {
    static let shared = AssociationHandler()
    private let db = Firestore.firestore()
    
    // MARK: - Public Methods
    
    /// Henter alle ejerforeninger med caching og offline support
    func fetchAssociations(insertAllAtTop: Bool) async throws -> [String] {
        let snapshot = try await db.collection("associations")
            .order(by: "name")
            .getDocuments()
        
        return processSnapshot(snapshot, insertAllAtTop: insertAllAtTop)
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
        
        var errorDescription: String? {
            switch self {
            case .firestoreError(let error):
                return "Firestore fejl: \(error.localizedDescription)"
            case .emptyResult:
                return "Ingen foreninger fundet"
            }
        }
    }
} 
