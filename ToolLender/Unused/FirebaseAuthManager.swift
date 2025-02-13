import FirebaseAuth

/// Håndterer autentificering med Firebase Authentication
final class FirebaseAuthManager {
    
    // MARK: - Shared Instance
    static let shared = FirebaseAuthManager()
    private init() {}
    
    // MARK: - Public Properties
    var currentUser: User? {
        Auth.auth().currentUser
    }
}

// MARK: - Authentication Methods
extension FirebaseAuthManager {
    /// Logger en bruger ind med email og password
    /// - Parameters:
    ///   - email: Brugerens email
    ///   - password: Brugerens password
    ///   - completion: Resultat af login-forsøg
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            self.handleAuthResult(result: result, error: error, completion: completion)
        }
    }
    
    /// Opretter en ny bruger med email og password
    /// - Parameters:
    ///   - email: Brugerens email
    ///   - password: Brugerens password
    ///   - completion: Resultat af registreringsforsøg
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            self.handleAuthResult(result: result, error: error, completion: completion)
        }
    }
    
    /// Logger den aktuelle bruger ud
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    /// Sletter den aktuelle bruger permanent
    func deleteCurrentUser() async throws {
        guard let user = currentUser else {
            throw AuthError.userNotLoggedIn
        }
        try await user.delete()
    }
}

// MARK: - Private Helpers
private extension FirebaseAuthManager {
    /// Håndterer generisk auth-resultat
    func handleAuthResult(result: AuthDataResult?, error: Error?, completion: @escaping (Result<User, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let user = result?.user else {
            completion(.failure(AuthError.unknown))
            return
        }
        
        completion(.success(user))
    }
}

// MARK: - Error Handling
extension FirebaseAuthManager {
    enum AuthError: LocalizedError {
        case userNotLoggedIn
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .userNotLoggedIn:
                return "Ingen bruger er logget ind"
            case .unknown:
                return "Ukendt fejl ved autentificering"
            }
        }
    }
}


