import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI
import FirebaseAuth
import Network
import Inject

enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case alphabetical = "Alphabetical"
    case oldest = "Oldest"

    var id: String { self.rawValue }
}

struct ToolListView: View {
    @ObserveInjection var inject
    @Binding var userAssociation: String
    @State private var tools: [Tool] = []
    @State private var filteredTools: [Tool] = []
    @State private var searchText: String = ""
    @State private var showProfileView = false
    @State private var isLoggedOut = false
    @State private var showDeleteConfirmation = false
    @State private var toolToDelete: Tool?
    @State private var selectedSortOption: SortOption = .newest

    private var currentUserUID: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        NavigationStack {
            VStack {
                searchField
                sortPicker
                toolList
                uploadButton
            }
            .onAppear {
                Task {
                    await fetchUserAssociation()
                    await fetchTools()
                }
                NetworkMonitorHandler.shared.startMonitoring { isOnline in
                    if isOnline {
                        print("Internet connection restored, reloading tools")
                        Task {
                            await fetchTools()
                        }
                    } else {
                        print("No internet connection")
                    }
                }
            }
            .onChange(of: userAssociation) {
                Task {
                    await fetchTools()
                }
            }
            .onChange(of: selectedSortOption) { _ in
                sortTools()
            }
            .alert("Delete Tool?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteConfirmedTool()
                }
            } message: {
                Text("Are you sure you want to delete this item?")
            }
            .fullScreenCover(isPresented: $showProfileView) {
                ProfileView(onLogout: {
                    isLoggedOut = true
                }, selectedAssociation: $userAssociation)
            }
            .fullScreenCover(isPresented: $isLoggedOut) {
                ContentView(selectedAssociation: $userAssociation)
            }
        }
        .enableInjection()
    }

    private var searchField: some View {
        TextField("Search items...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .onChange(of: searchText) {
                filterTools(by: searchText)
            }
    }

    private var sortPicker: some View {
        Picker("Sort by", selection: $selectedSortOption) {
            ForEach(SortOption.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }

    private var toolList: some View {
        List {
            ForEach(filteredTools) { tool in
                NavigationLink(destination: ToolDetailLoader(tool: tool)) {
                    toolRow(for: tool)
                }
                .disabled(tool.isOnHold)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if tool.ownerUID == currentUserUID {
                        Button {
                            toggleHoldStatus(for: tool)
                        } label: {
                            Label(tool.isOnHold ? "Unhold" : "Hold", systemImage: tool.isOnHold ? "play.circle" : "pause.circle")
                        }
                        .tint(tool.isOnHold ? .green : .orange)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if tool.ownerUID == currentUserUID {
                        Button(role: .destructive) {
                            toolToDelete = tool
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .refreshable {
            await fetchTools()
        }
        .navigationTitle(userAssociation)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showProfileView = true
                }) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            }
        }
    }

    private func toolRow(for tool: Tool) -> some View {
        HStack(spacing: 10) {
            if let imageURL = tool.imageURL, let url = URL(string: imageURL) {
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
                Text(tool.name)
                    .font(.headline)
                    .foregroundColor(tool.isOnHold ? .gray : .primary)
                Text(tool.description)
                    .font(.subheadline)
                    .foregroundColor(tool.isOnHold ? .gray : .secondary)
                if let price = tool.pricePerDay, price > 0 {
                    Text("Price: \(price, specifier: "%.2f") DKK/Day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Price: Free")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if tool.ownerUID == currentUserUID {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
            }
        }
    }

    private var uploadButton: some View {
        NavigationLink(destination: UploadToolView(userAssociation: $userAssociation)) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .padding()
        }
    }

    private func fetchUserAssociation() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        do {
            let document = try await db.collection("users").document(userUID).getDocument()
            if let data = document.data(), let association = data["association"] as? String {
                self.userAssociation = association
            }
        } catch {
            print("Error fetching user association: \(error.localizedDescription)")
        }
    }

    private func fetchTools() async {
        let loadedTools = await ToolHandler.shared.fetchAllToolsCachedFirst()
        self.tools = loadedTools

        filterTools(by: searchText)
    }

    private func toggleHoldStatus(for tool: Tool) {
        let db = Firestore.firestore()
        let newStatus = !tool.isOnHold
        db.collection("tools").document(tool.id).updateData(["isOnHold": newStatus]) { error in
            if let error = error {
                print("Error updating hold status: \(error.localizedDescription)")
            } else {
                if let index = tools.firstIndex(where: { $0.id == tool.id }) {
                    tools[index].isOnHold = newStatus
                    filterTools(by: searchText)
                }
            }
        }
    }

    private func filterTools(by query: String) {
        if userAssociation == "All" {
            filteredTools = tools
        } else {
            filteredTools = tools.filter { tool in
                tool.category == userAssociation
            }
        }

        if !query.isEmpty {
            filteredTools = filteredTools.filter { tool in
                tool.name.localizedCaseInsensitiveContains(query) ||
                tool.description.localizedCaseInsensitiveContains(query)
            }
        }

        sortTools()
    }

    private func sortTools() {
        switch selectedSortOption {
        case .alphabetical:
            filteredTools.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .newest:
            filteredTools.sort { $0.timestamp ?? Date() > $1.timestamp ?? Date() }
        case .oldest:
            filteredTools.sort { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
        }
    }

    private func deleteConfirmedTool() {
        guard let tool = toolToDelete else { return }
        let db = Firestore.firestore()

        db.collection("tools").document(tool.id).delete { error in
            if let error = error {
                print("Error deleting item: \(error.localizedDescription)")
            } else {
                if let index = tools.firstIndex(where: { $0.id == tool.id }) {
                    tools.remove(at: index)
                    filterTools(by: searchText)
                }
            }
        }

        toolToDelete = nil
    }
}
