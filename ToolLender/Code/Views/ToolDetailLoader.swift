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
        do {
            // Brug UserHandler til at hente brugerdata med cache-support
            let userInfo = try await UserHandler.shared.fetchUserData(userUID: tool.ownerUID, useCache: true)
            
            // Opdater UI med brugerdata
            ownerName = userInfo.name
            ownerEmail = userInfo.email
            ownerPhoneNumber = userInfo.phoneNumber ?? "Unknown"
            ownerAddress = userInfo.address ?? "Unknown"
            
            print("Fetched owner info: \(ownerName), \(ownerEmail), \(ownerPhoneNumber), \(ownerAddress)")
        } catch {
            print("Error fetching owner info: \(error.localizedDescription)")
        }
    }
}


