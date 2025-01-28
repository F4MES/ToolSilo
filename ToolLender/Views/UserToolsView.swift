import SwiftUI
import FirebaseFirestore
import Inject
import SDWebImageSwiftUI

/// Viser en liste af værktøjer, der ejes af en bestemt bruger (via ownerUID)
struct UserToolsView: View {
    @ObserveInjection var inject
    let ownerUID: String
    @State private var tools: [Tool] = []

    var body: some View {
        List(tools) { tool in
            HStack {
                if let imageUrl = tool.imageURL, let url = URL(string: imageUrl) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                }
                VStack(alignment: .leading) {
                    Text(tool.name).font(.headline)
                    Text(tool.description).font(.subheadline)
                }
            }
        }
        .navigationTitle("User's Tools")
        .task {
            await fetchTools()
        }
        .enableInjection()
    }

    /// Henter værktøjer fra Firestore for en specifik ejer
    private func fetchTools() async {
        do {
            self.tools = try await ToolHandler.shared.fetchToolsByOwner(ownerUID: ownerUID)
        } catch {
            print("Error fetching tools: \(error.localizedDescription)")
        }
    }
} 