import SwiftUI
import FirebaseFirestore
import Inject

struct ToolDetailLoader: View {
    let tool: Tool
    @State private var ownerData: UserInfo?
    
    var body: some View {
        Group {
            if let ownerData = ownerData {
                ToolDetailView(
                    tool: tool,
                    ownerName: ownerData.name,
                    ownerEmail: ownerData.email,
                    ownerPhoneNumber: ownerData.phoneNumber ?? "Unknown",
                    ownerAddress: ownerData.address ?? "Unknown"
                )
            } else {
                ProgressView()
            }
        }
        .task {
            await fetchOwnerInfo()
        }
    }
    
    private func fetchOwnerInfo() async {
        do {
            ownerData = try await UserHandler.shared.fetchUserData(userUID: tool.ownerUID)
        } catch {
            print("Fejl ved hentning af ejer: \(error.localizedDescription)")
        }
    }
}


