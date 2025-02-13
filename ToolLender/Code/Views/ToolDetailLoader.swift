import SwiftUI
import FirebaseFirestore
import Inject

struct ToolDetailLoader: View {
    let tool: Tool // Det værktøj, der skal vises
    @State private var ownerName = "" // Ejerens navn
    @State private var ownerEmail = "" // Ejerens email
    @State private var ownerPhoneNumber = "" // Ejerens telefonnummer
    @State private var ownerAddress = "" // Ejerens adresse

    var body: some View {
        ToolDetailView(
            tool: tool,
            ownerName: ownerName,
            ownerEmail: ownerEmail,
            ownerPhoneNumber: ownerPhoneNumber,
            ownerAddress: ownerAddress
        )
        .task {
            await fetchOwnerInfo() // Henter ejeroplysninger ved visning
        }
    }

    // Henter ejeroplysninger fra Firestore
    private func fetchOwnerInfo() async {
        let db = Firestore.firestore()
        do {
            let document = try await db.collection("users").document(tool.ownerUID).getDocument()
            guard let data = document.data() else {
                print("No data found for UID: \(tool.ownerUID)") // Logger, hvis der ikke findes data
                return
            }

            ownerName = data["name"] as? String ?? "Unknown"
            ownerEmail = data["email"] as? String ?? "Unknown"
            ownerPhoneNumber = data["phoneNumber"] as? String ?? "Unknown"
            ownerAddress = data["address"] as? String ?? "Unknown"

            print("Fetched owner info: \(ownerName), \(ownerEmail), \(ownerPhoneNumber), \(ownerAddress)")
        } catch {
            print("Error fetching owner info: \(error.localizedDescription)") // Logger fejl ved hentning
        }
    }
}


