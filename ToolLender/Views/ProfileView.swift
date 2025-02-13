import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Inject
import SDWebImageSwiftUI

struct ProfileView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    var onLogout: () -> Void
    @ObserveInjection var inject

    // MARK: - States
    @State private var userTools: [Tool] = []
    @State private var showDeleteConfirmation = false
    @State private var toolToDelete: Tool?
    @Binding var selectedAssociation: String
    @State private var associations: [String] = []
    @State private var newAssociation: String = ""
    @State private var showAddAssociationAlert = false
    @State private var userName: String = "Your Profile"
    @State private var showEditProfile = false
    @State private var showDeleteUserAlert = false
    @State private var showLogoutConfirmation = false

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                        
                        Text(userName)
                            .font(.title2.bold())
                        
                        Text(Auth.auth().currentUser?.email ?? "No email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        NavigationLink(destination: EditProfileView()) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Profile")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        
                        Button {
                            showLogoutConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left.square")
                                Text("Log Out")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(10)
                        }
                        
                        Button {
                            showDeleteUserAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Association Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Your Association")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showAddAssociationAlert = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Picker("Select Association", selection: $selectedAssociation) {
                            ForEach(associations, id: \.self) { association in
                                Text(association).tag(association)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.1), radius: 5)
                    .padding(.horizontal)
                    
                    // Tools List
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Your Tools")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if userTools.isEmpty {
                            Text("No tools available")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            List {
                                ForEach(userTools) { tool in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(tool.name)
                                                .font(.headline)
                                                .foregroundColor(tool.isOnHold ? .gray : .primary)
                                            Text(tool.description)
                                                .font(.subheadline)
                                                .foregroundColor(tool.isOnHold ? .gray : .secondary)
                                            
                                            HStack {
                                                Image(systemName: "building.2")
                                                    .font(.system(size: 12))
                                                Text(tool.category)
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.blue)
                                            .padding(.vertical, 4)
                                        }
                                        Spacer()
                                        if tool.isOnHold {
                                            Image(systemName: "pause.circle")
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            toggleHoldStatus(for: tool)
                                        } label: {
                                            Label(tool.isOnHold ? "Activate" : "Pause", 
                                                  systemImage: tool.isOnHold ? "play.circle" : "pause.circle")
                                        }
                                        .tint(tool.isOnHold ? .green : .orange)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            toolToDelete = tool
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .frame(height: 300)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Add New Association", isPresented: $showAddAssociationAlert) {
                TextField("Association Name", text: $newAssociation)
                Button("Cancel", role: .cancel) {}
                Button("Add") { addNewAssociation() }
            }
            .alert("Delete Tool?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteTool() }
            } message: {
                Text("Are you sure you want to delete this tool?")
            }
            .alert("Delete Account", isPresented: $showDeleteUserAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteUser() }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) { logOut() }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
        .task {
            loadCachedUserInfo()
            await fetchUserTools()
            await fetchUserAssociation()
            await fetchAssociations()
            await fetchUserName()
        }
        .enableInjection()
    }

    // MARK: - UI Components
    struct ToolCardView: View {
        let tool: Tool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if let imageURL = tool.imageURL, let url = URL(string: imageURL) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tool.name)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        
                        Text(tool.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.system(size: 12))
                            Text(tool.category)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: tool.isOnHold ? "pause.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(tool.isOnHold ? .orange : .green)
                        
                        if let price = tool.pricePerDay, price > 0 {
                            Text("\(price, specifier: "%.2f") DKK/day")
                                .font(.caption2)
                                .padding(5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(5)
                        } else {
                            Text("Free")
                                .font(.caption2)
                                .padding(5)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(5)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Henter cached info
    private func loadCachedUserInfo() {
        Task {
            do {
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                let userData = try await UserHandler.shared.fetchUserData(userUID: userUID)
                
                self.userName = userData?["name"] as? String ?? "Bruger"
                self.selectedAssociation = userData?["association"] as? String ?? "All"
            } catch {
                print("Fejl ved cache-hentning: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Log ud
    private func logOut() {
        do {
            try Auth.auth().signOut()
            onLogout() // Kalder callback for at håndtere navigation
            dismiss() // Lukker ProfileView
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // MARK: - Værktøjer
    private func fetchUserTools() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            self.userTools = try await ToolHandler.shared.fetchToolsByOwner(ownerUID: userUID)
        } catch {
            print("Error fetching user tools: \(error.localizedDescription)")
        }
    }

    private func toggleHoldStatus(for tool: Tool) {
        Task {
            do {
                try await ToolHandler.shared.toggleHoldStatus(for: tool)
                if let index = userTools.firstIndex(where: { $0.id == tool.id }) {
                    userTools[index].isOnHold.toggle()
                }
            } catch {
                print("Error updating hold status: \(error.localizedDescription)")
            }
        }
    }

    private func deleteTool() {
        guard let tool = toolToDelete else { return }
        Task {
            do {
                try await ToolHandler.shared.deleteTool(tool)
                if let index = userTools.firstIndex(where: { $0.id == tool.id }) {
                    userTools.remove(at: index)
                }
            } catch {
                print("Error deleting tool: \(error.localizedDescription)")
            }
        }
        toolToDelete = nil
    }

    // MARK: - Slet bruger
    private func deleteUser() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await UserHandler.shared.deleteUser(userUID: userUID)
                onLogout()
                dismiss()
            } catch {
                print("Failed to delete user: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Associations
    private func fetchUserAssociation() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            let assoc = try await UserHandler.shared.fetchUserAssociation(userUID: userUID)
            self.selectedAssociation = assoc
        } catch {
            print("Error fetching user association: \(error.localizedDescription)")
        }
    }

    private func fetchAssociations() async {
        do {
            self.associations = try await AssociationHandler.shared.fetchAssociations(insertAllAtTop: true)
        } catch {
            print("Error fetching associations: \(error.localizedDescription)")
        }
    }

    private func saveUserAssociation(_ association: String) {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await UserHandler.shared.updateUserFields(
                    userUID: userUID, 
                    updates: ["association": association]
                )
                // Firebase håndterer automatisk caching
            } catch {
                print("Fejl ved opdatering af forening: \(error.localizedDescription)")
            }
        }
    }

    private func addNewAssociation() {
        let newAssociationName = newAssociation.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await AssociationHandler.shared.addAssociation(name: newAssociationName)
                associations.append(newAssociationName)
            } catch {
                print("Error adding association: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Brugeroplysninger
    private func fetchUserName() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            if let name = try await UserHandler.shared.fetchUserName(userUID: userUID) {
                self.userName = name
            }
        } catch {
            print("Fejl ved navnehentning: \(error.localizedDescription)")
        }
    }
}
