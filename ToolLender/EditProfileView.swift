import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// View til at redigere brugerens profiloplysninger (email, pw, telefon osv.)
struct EditProfileView: View {
    // MARK: - State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    @State private var errorMessage: String = ""
    @State private var showSuccessAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Inputs
            TextField("New Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("New Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("New Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.phonePad)

            TextField("New Address", text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Save Changes") {
                updateProfile()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Your profile has been updated successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Update Profile
    private func updateProfile() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not logged in."
            return
        }
        
        var updates: [String: Any] = [:]
        if !phoneNumber.isEmpty {
            updates["phoneNumber"] = phoneNumber
        }
        if !address.isEmpty {
            updates["address"] = address
        }


        Task {
            do {
                try await UserHandler.shared.updateUserFields(userUID: user.uid, updates: updates)
                // Tjek for success:
                checkForSuccess()
            } catch {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Opdater Firestore-felter
    private func updateFirestoreFields(userUID: String) async {
        // Fjernet Implementér Firestore-opdatering
    }

    private func checkForSuccess() {
        if errorMessage.isEmpty {
            showSuccessAlert = true
        }
    }
} 
