import FirebaseAuth

/// Manager til Firebase Authentication (login, logout, opret bruger)
class FirebaseAuthManager {
    static let shared = FirebaseAuthManager()

    private init() {}

    /// Logger brugeren ind med email/password. Returnerer en Firebase `User` ved succes.
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error)) // Returnerer fejl
            } else if let user = result?.user {
                completion(.success(user)) // Returnerer bruger
            }
        }
    }

    /// Opretter en bruger med email/password. Returnerer en Firebase `User` ved succes.
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error)) // Returnerer fejl
            } else if let user = result?.user {
                completion(.success(user)) // Returnerer bruger
            }

        }
    }

    /// Logger brugeren ud af FirebaseAuth-sammenhæng
    func signOut() throws {
        try Auth.auth().signOut() // Forsøger at logge brugeren ud
    }
}
