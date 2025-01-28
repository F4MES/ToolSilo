import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Inject
import Foundation

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
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding(.trailing, 10)

                    Text(userName)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding()

                // Viser den nuværende brugers email
                Text("Email: \(Auth.auth().currentUser?.email ?? "Unknown")")
                    .font(.title3)

                // Knap til at redigere profil
                Button("Edit Profile") {
                    showEditProfile = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .sheet(isPresented: $showEditProfile) {
                    EditProfileView()
                }

                // Overskrift for ejerforening
                HStack {
                    Text("Current Association")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        showAddAssociationAlert = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                // Vælg ejerforening
                Picker("Select Association", selection: $selectedAssociation) {
                    ForEach(associations, id: \.self) { association in
                        Text(association)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedAssociation) { newValue in
                    saveUserAssociation(newValue)
                }

                // Liste over brugerens værktøjer
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
                                Text("Association: \(tool.category)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        .swipeActions(edge: .leading) {
                            Button {
                                toggleHoldStatus(for: tool)
                            } label: {
                                Label(tool.isOnHold ? "Unhold" : "Hold", systemImage: tool.isOnHold ? "play.circle" : "pause.circle")
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
                .alert("Delete Tool?", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        deleteTool()
                    }
                } message: {
                    Text("Are you sure you want to delete this item?")
                }

                Spacer() // Tilføj en spacer for at skubbe knapperne til bunden

                // Log Out knap
                Button("Log Out") {
                    showLogoutConfirmation = true
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .alert(isPresented: $showLogoutConfirmation) {
                    Alert(
                        title: Text("Log Out"),
                        message: Text("Are you sure you want to log out?"),
                        primaryButton: .destructive(Text("Log Out")) {
                            logOut()
                        },
                        secondaryButton: .cancel()
                    )
                }

                // Delete User knap
                Button("Delete User") {
                    showDeleteUserAlert = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                .alert(isPresented: $showDeleteUserAlert) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteUser()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss() // Lukker visningen
                    }) {
                        Text("Close")
                    }
                }
            }
            .alert("Add New Association", isPresented: $showAddAssociationAlert) {
                TextField("Association Name", text: $newAssociation)
                Button("Add", action: addNewAssociation)
                Button("Cancel", role: .cancel) {}
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

    // MARK: - Henter cached info
    private func loadCachedUserInfo() {
        if let cachedUserInfo = LocalCacheManager.shared.loadUserInfo() {
            self.userName = cachedUserInfo.name
            self.selectedAssociation = cachedUserInfo.association
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
            // ... gem i cache??
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
        let db = Firestore.firestore()

        db.collection("users").document(userUID).setData(["association": association], merge: true) { error in
            if let error = error {
                print("Error saving user association: \(error.localizedDescription)")
            } else {
                // Opdaterer cachen med den nye forening
                if let email = Auth.auth().currentUser?.email {
                    let userInfo = UserInfo(name: self.userName, email: email, association: association)
                    LocalCacheManager.shared.saveUserInfo(userInfo)
                }
            }
        }
    }

    private func addNewAssociation() {
        let db = Firestore.firestore()
        let newAssociationName = newAssociation.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !newAssociationName.isEmpty else { return }

        db.collection("associations").whereField("name", isEqualTo: newAssociationName).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking association: \(error.localizedDescription)")
                return
            }

            if snapshot?.isEmpty == true {
                db.collection("associations").addDocument(data: ["name": newAssociationName]) { error in
                    if let error = error {
                        print("Error adding association: \(error.localizedDescription)")
                    } else {
                        associations.append(newAssociationName)
                    }
                }
            } else {
                print("Association already exists.")
            }
        }
    }

    // MARK: - Brugeroplysninger
    private func fetchUserName() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            let name = try await UserHandler.shared.fetchUserName(userUID: userUID)
            if let fetchedName = name {
                self.userName = fetchedName
            }
            // ... gem i cache??
        } catch {
            print("Error fetching user name: \(error.localizedDescription)")
        }
    }
}