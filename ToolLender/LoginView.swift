//Create a frontpage with a login view and a register view.
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Inject

// MARK: - ContentView
/// Viser enten ToolListView (hvis logget ind) eller login-/registervalgmuligheder (hvis logget ud)
struct ContentView: View {
    @State private var isLoggedIn = false // Styrer om brugeren er logget ind
    @Binding var selectedAssociation: String // Valgt ejerforening
    @ObserveInjection var inject // Bruges til hot reloading

    var body: some View {
        Group {
            if isLoggedIn {
                ToolListView(userAssociation: $selectedAssociation) // Passer bindingen til ToolListView
            } else {
                NavigationStack {
                    VStack(spacing: 20) {
                        Image("logosilo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 400)
                            .foregroundStyle(.blue)

                        Image(systemName: "wrench.and.screwdriver")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.tint)

                        Spacer()

                        VStack(spacing: 15) {
                            // Navigation til registreringsvisning
                            NavigationLink(destination: RegisterView(onRegisterSuccess: {
                                isLoggedIn = true
                            })) {
                                Text("Register")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 40)

                            // Navigation til loginvisning
                            NavigationLink(destination: LoginView(onLoginSuccess: {
                                isLoggedIn = true
                            })) {
                                Text("Login")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            checkLoginStatus() // Tjekker loginstatus ved visning
        }
        .enableInjection() // Aktiverer hot reloading
    }

    // MARK: - Checker om brugeren allerede er logget ind
    private func checkLoginStatus() {
        if Auth.auth().currentUser != nil {
            isLoggedIn = true
        }
    }
}

// MARK: - LoginView
// Håndterer login med email/password
struct LoginView: View {
    @State private var email = "" // Brugerens email
    @State private var password = "" // Brugerens password
    @State private var errorMessage = "" // Fejlmeddelelse ved login
    @ObserveInjection var inject // Bruges til hot reloading

    var onLoginSuccess: (() -> Void)? // Callback-funktion ved succesfuldt login

    var body: some View {
        VStack(spacing: 20) {
            Image("logosilo")
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 400)
                .foregroundStyle(.blue)

            Text("Login")
                .font(.title)
                .padding()

            // Indtastningsfelt for email
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)

            // Indtastningsfelt for password
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Viser fejlmeddelelse, hvis der er en
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // Knap til at logge ind
            Button(action: loginUser) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .enableInjection() // Aktiverer hot reloading
    }

    // Logger brugeren ind med Firebase Authentication
    private func loginUser() {
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                let user = result.user
                errorMessage = ""

                // Hent Firestore-dokument for den loggede bruger
                let db = Firestore.firestore()
                let doc = try await db.collection("users").document(user.uid).getDocument()

                // Efter succes:
                if let data = doc.data() {
                    let name = data["name"] as? String ?? "Unknown"
                    let association = data["association"] as? String ?? "All"
                    // Gem i cachen, hvis du ønsker
                    LocalCacheManager.shared.saveUserInfo(
                        UserInfo(name: name, email: user.email ?? "", association: association)
                    )
                }
                onLoginSuccess?()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - RegisterView
// Håndterer oprettelse af ny bruger med email/password
struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    @State private var selectedAssociation: String = "The Silo" // Standardvalgt forening
    @State private var associations = ["The Silo", "UMEUS", "STAY"] // Eksempel på ejerforeninger
    @State private var errorMessage: String = ""
    @State private var registrationSuccessful: Bool = false

    var onRegisterSuccess: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.phonePad)

            TextField("Address", text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Vælg ejerforening
            Picker("Select Association", selection: $selectedAssociation) {
                ForEach(associations, id: \.self) { association in
                    Text(association)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            Button(action: registerUser) {
                Text("Register")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .alert(isPresented: $registrationSuccessful) {
            Alert(
                title: Text("Success"),
                message: Text("User registered successfully!"),
                dismissButton: .default(Text("OK"), action: {
                    onRegisterSuccess?() // Kalder callback-funktionen
                })
            )
        }
        .onAppear {
            // Hent associations fra Firestore, fx:
            Task {
                do {
                    let fetched = try await AssociationHandler.shared.fetchAssociations(insertAllAtTop: false)
                    self.associations = fetched
                } catch {
                    print("Failed to fetch associations in RegisterView: \(error.localizedDescription)")
                    // Evt. fallback til en cached liste eller en tom liste
                }
            }
        }
    }

    // Registrerer en ny bruger med Firebase Authentication
    private func registerUser() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match" // Viser fejl, hvis passwords ikke matcher
            return
        }

        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                saveUserToFirestore(user: result.user) // Gemmer brugeroplysninger i Firestore
                registrationSuccessful = true // Indikerer succesfuld registrering
                errorMessage = "" // Nulstiller fejlmeddelelsen
            } catch {
                errorMessage = error.localizedDescription // Viser fejlmeddelelse
            }
        }
    }

    // Gemmer brugeroplysninger i Firestore
    private func saveUserToFirestore(user: User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "name": name,
            "email": email,
            "phoneNumber": phoneNumber,
            "address": address,
            "association": selectedAssociation // Gemmer den valgte forening
        ]) { error in
            if let error = error {
                errorMessage = "Failed to save user: \(error.localizedDescription)" // Viser fejlmeddelelse
            }
        }
    }
}
#Preview {
    ContentView(selectedAssociation: .constant(""))
}
