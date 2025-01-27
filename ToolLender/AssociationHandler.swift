import FirebaseFirestore
import Foundation

/// Håndterer kald til Firestore for at hente/administrere associations.
class AssociationHandler {
    static let shared = AssociationHandler()
    private init() {}

    /// Henter alle foreninger fra Firestore og tilføjer "All" øverst, hvis `insertAllAtTop` er true.
    func fetchAssociations(insertAllAtTop: Bool) async throws -> [String] {
        // 1) Tjek cachen først
        if LocalCacheManager.shared.hasCachedAssociations() {
            let cached = LocalCacheManager.shared.loadAssociations()
            if !cached.isEmpty {
                // Returner cachen, men tilføj "All" hvis ønsket
                var associations = cached
                if insertAllAtTop && !associations.contains("All") {
                    associations.insert("All", at: 0)
                }
                return associations
            }
        }

        // 2) Hvis cachen er tom, hent dem online
        let db = Firestore.firestore()
        let snapshot = try await db.collection("associations").getDocuments()
        var associations = snapshot.documents.compactMap { $0.data()["name"] as? String }

        if insertAllAtTop && !associations.contains("All") {
            associations.insert("All", at: 0)
        }

        // 3) Gem i cachen, så vi har den næste gang
        LocalCacheManager.shared.saveAssociations(associations)
        return associations
    }
} 
