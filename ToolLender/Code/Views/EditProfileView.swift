import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// View for editing user profile information including contact details
struct EditProfileView: View {
    // MARK: - State Properties
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    @State private var errorMessage: String = ""
    @State private var showSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var isLoading = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Edit Profile")
                .toolbar { loadingIndicator }
        }
        .alert("Profile Updated", isPresented: $showSuccessAlert) {
            Button("OK") { }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Main Content
    private var content: some View {
        Form {
            Section(header: Text("Contact Information")) {
                emailSection
                phoneNumberSection
                addressSection
            }
            
            Section(header: Text("Password")) {
                passwordSection
                confirmPasswordSection
            }
            
            Section {
                saveButton
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - View Components
extension EditProfileView {
    private var emailSection: some View {
        TextField("New Email", text: $email)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
    
    private var phoneNumberSection: some View {
        TextField("New Phone Number", text: $phoneNumber)
            .keyboardType(.phonePad)
    }
    
    private var addressSection: some View {
        TextField("New Address", text: $address)
    }
    
    private var passwordSection: some View {
        SecureField("New Password", text: $password)
    }
    
    private var confirmPasswordSection: some View {
        SecureField("Confirm Password", text: $confirmPassword)
    }
    
    private var saveButton: some View {
        Button(action: updateProfile) {
            HStack {
                Spacer()
                Text("Save Changes")
                    .fontWeight(.semibold)
                Spacer()
            }
        }
        .listRowBackground(Color.blue)
        .foregroundColor(.white)
    }
    
    private var loadingIndicator: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - Business Logic
extension EditProfileView {
    /// Validates and updates user profile information
    private func updateProfile() {
        guard validateInputs() else { return }
        
        isLoading = true
        Task {
            do {
                try await performUpdates()
                showSuccessAlert = true
                errorMessage = ""
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    /// Validates user input before proceeding with updates
    private func validateInputs() -> Bool {
        guard !password.isEmpty || !confirmPassword.isEmpty else { return true }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showingErrorAlert = true
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showingErrorAlert = true
            return false
        }
        
        return true
    }
    
    /// Performs the actual update operations
    private func performUpdates() async throws {
        guard let user = Auth.auth().currentUser else {
            throw ProfileError.userNotLoggedIn
        }
        
        var updates = [String: Any]()
        try await updateEmailIfNeeded(user: user)
        try await updatePasswordIfNeeded(user: user)
        updateProfileFields(&updates)
        
        if !updates.isEmpty {
            try await UserHandler.shared.updateUserFields(
                userUID: user.uid, 
                updates: updates
            )
        }
    }
    
    /// Updates email if changed and valid
    private func updateEmailIfNeeded(user: User) async throws {
        guard !email.isEmpty, email != user.email else { return }
        guard email.isValidEmail else {
            throw ProfileError.invalidEmail
        }
        
        try await user.sendEmailVerification(beforeUpdatingEmail: email)
    }
    
    /// Updates password if changed and valid
    private func updatePasswordIfNeeded(user: User) async throws {
        guard !password.isEmpty else { return }
        try await user.updatePassword(to: password)
    }
    
    /// Prepares profile field updates
    private func updateProfileFields(_ updates: inout [String: Any]) {
        if !phoneNumber.isEmpty {
            updates["phoneNumber"] = phoneNumber
        }
        if !address.isEmpty {
            updates["address"] = address
        }
    }
    
    /// Handles errors and displays appropriate messages
    private func handleError(_ error: Error) {
        switch error {
        case AuthErrorCode.invalidEmail:
            errorMessage = "Please enter a valid email address"
        case AuthErrorCode.requiresRecentLogin:
            errorMessage = "Please re-authenticate to change sensitive information"
        case ProfileError.invalidEmail:
            errorMessage = "Please enter a valid email address"
        default:
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        showingErrorAlert = true
    }
}

// MARK: - Error Handling
extension EditProfileView {
    private enum ProfileError: LocalizedError {
        case userNotLoggedIn
        case invalidEmail
        
        var errorDescription: String? {
            switch self {
            case .userNotLoggedIn: 
                return "User not logged in"
            case .invalidEmail: 
                return "Invalid email format"
            }
        }
    }
}

// MARK: - String Extension
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
} 
