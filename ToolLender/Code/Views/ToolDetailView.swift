import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import Inject

struct ToolDetailView: View {
    @ObserveInjection var inject // Bruges til hot reloading
    
    let tool: Tool // Det værktøj, der skal vises
    let ownerName: String // Ejerens navn
    let ownerEmail: String // Ejerens email
    let ownerPhoneNumber: String // Ejerens telefonnummer
    let ownerAddress: String // Ejerens adresse
    @State private var otherTools: [Tool] = [] // Liste over andre værktøjer fra ejeren
    @State private var showContactOptions = false // Styrer visningen af kontaktmuligheder

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Viser værktøjets billede
                if let imageURL = tool.imageURL, let url = URL(string: imageURL) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                }

                // Viser værktøjets beskrivelse og pris
                Text(tool.description)
                    .font(.body)

                if let price = tool.pricePerDay, price > 0 {
                    Text("Price: \(price, specifier: "%.2f") DKK/day")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Price: Free")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Tilføj lokationsknap her
                Button(action: {
                    openMap(for: ownerAddress)
                }) {
                    HStack {
                        Image(systemName: "map")
                        Text("Show on Map")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.vertical, 5)

                Divider()

                // Knap til at kontakte ejeren
                Button(action: {
                    showContactOptions = true
                }) {
                    Text("Contact")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .actionSheet(isPresented: $showContactOptions) {
                    ActionSheet(
                        title: Text("Contact Owner"),
                        message: Text("Choose a method to contact the owner."),
                        buttons: [
                            .default(Text("Email")) {
                                sendEmail(to: ownerEmail)
                            },
                            .default(Text("SMS")) {
                                sendSMS(to: ownerPhoneNumber)
                            },
                            .cancel()
                        ]
                    )
                }

                Divider()

                // Viser andre værktøjer fra ejeren
                Text("Other Items by \(ownerName)")
                    .font(.title2)
                    .fontWeight(.semibold)

                List {
                    ForEach(otherTools) { otherTool in
                        NavigationLink(destination: ToolDetailLoader(tool: otherTool)) {
                            HStack(spacing: 10) {
                                if let imageURL = otherTool.imageURL, let url = URL(string: imageURL) {
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
                                    Text(otherTool.name)
                                        .font(.headline)
                                    Text(otherTool.description)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .frame(height: 200) // Begrænser højden af listen

                Spacer()
            }
            .padding()
        }
        .navigationTitle(tool.name) // Sæt værktøjets navn som titel
        .task {
            await fetchOtherTools() // Henter andre værktøjer ved visning
        }
        .enableInjection() // Aktiverer hot reloading
    }

    // Åbner mailklienten med den angivne email
    private func sendEmail(to email: String) {
        if let emailURL = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(emailURL)
        }
    }

    // Åbner SMS-klienten med det angivne telefonnummer
    private func sendSMS(to phoneNumber: String) {
        if let smsURL = URL(string: "sms:\(phoneNumber)") {
            UIApplication.shared.open(smsURL)
        }
    }

    // Åbner kortapplikationen
    private func openMap(for address: String) {
        let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let mapURL = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(mapURL)
        }
    }

    // Henter andre værktøjer fra Firestore for den angivne ejer
   private func fetchOtherTools() async {
    do {
        self.otherTools = try await ToolHandler.shared.fetchToolsByOwner(ownerUID: tool.ownerUID)
            .filter { $0.id != tool.id }
    } catch {
        print("Error fetching tools: \(error.localizedDescription)")
    }
} 
}
