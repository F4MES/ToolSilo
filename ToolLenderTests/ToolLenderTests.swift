import Foundation
import Testing
@testable import ToolLender
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore

@Suite
struct ToolLenderTests {
    var auth: Auth!
    var db: Firestore!
    var storage: Storage!
    var toolHandler: ToolHandler!
    var userHandler: UserHandler!
    var associationHandler: AssociationHandler!
    
    init() {
        // Firebase konfiguration
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            
            // Konfigurer emulator
        let firestore = Firestore.firestore()
            firestore.useEmulator(withHost: "localhost", port: 8080)
            
            Auth.auth().useEmulator(withHost: "localhost", port: 9099)
            Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        }
        
        // Initialiser
        auth = Auth.auth()
        db = Firestore.firestore()
        storage = Storage.storage()
        toolHandler = ToolHandler.shared
        userHandler = UserHandler.shared
        associationHandler = AssociationHandler.shared
    }
    
    // MARK: - User Story 1: Login
    @Test
    func successfulLogin() async throws {
        // Given
        let email = "test@swifttesting.com"
        let password = "swift123"
        
        // Forsøg at oprette bruger, ignorer fejl hvis bruger eksisterer
        do {
            let _ = try await auth.createUser(withEmail: email, password: password)
        } catch let error as NSError {
            // log fejlen hvis det ikke er fordi brugeren allerede findes !!!!!!!!!!
            if error.code != 17007 { // ERROR_EMAIL_ALREADY_IN_USE kode
                print("Fejl ved oprettelse: \(error.localizedDescription)")
            }
        }
        
        // When
        let user = try await auth.signIn(withEmail: email, password: password)
        
        // Then
        #expect(user.user.email == email)
    }
    
    // MARK: - User Story 2: Værktøjsliste
    @Test
    func fetchTools() async throws {
        // Given
        let testToolId = "swiftTest123"
        let testData: [String: Any] = [
            "name": "Swift Test Værktøj",
            "description": "Swift Testing",
            "imageURL": NSNull(),
            "ownerUID": "swiftTester",
            "pricePerDay": 99.0,
            "category": "SwiftTests",
            "isOnHold": false,
            "timestamp": Timestamp(date: Date())
        ]
        
        // When
        try await db.collection("tools").document(testToolId).setData(testData)
        
        // Then
        let doc = try await db.collection("tools").document(testToolId).getDocument()
        #expect(doc.exists)
        
        let data = doc.data()
        #expect(data?["name"] as? String == "Swift Test Værktøj")
    }
    
    // MARK: - User Story 3: Opret værktøj
    @Test
    func createTool() async throws {
        // Given
        let toolData: [String: Any] = [
            "name": "Swift Hammer",
            "description": "Swift Test Hammer",
            "pricePerDay": 88.0,
            "ownerUID": "swiftUser",
            "category": "SwiftTools",
            "isOnHold": false,
            "timestamp": Timestamp(date: Date())
        ]
        
        // When
        let documentRef = try await db.collection("tools").addDocument(data: toolData)
        let document = try await documentRef.getDocument()
        
        // Then
        #expect(document.exists)
        #expect(document.get("name") as? String == "Swift Hammer")
    }
    
    // MARK: - User Story 5: Pause opslag
    @Test
    func toggleHoldStatus() async throws {
        // Given
        let testToolId = "swiftPauseTest"
        let testData: [String: Any] = [
            "name": "Swift Pause",
            "description": "Swift Test",
            "imageURL": NSNull(),
            "ownerUID": "swiftUser",
            "pricePerDay": 0.0,
            "category": "SwiftTest",
            "isOnHold": false,
            "timestamp": Timestamp(date: Date())
        ]
        
        // When
        try await db.collection("tools").document(testToolId).setData(testData)
        
        // Toggle manuelt
        try await db.collection("tools").document(testToolId).updateData(["isOnHold": true])
        
        // Then
        let updatedDoc = try await db.collection("tools").document(testToolId).getDocument()
        #expect(updatedDoc.get("isOnHold") as? Bool == true)
    }
    
    // MARK: - User Story 8: Billedupload
    @Test
    func imageUpload() async throws {
        // Given
        let testImage = UIImage(systemName: "photo")!
        guard let imageData = testImage.pngData() else {
            throw TestError("Kunne ikke konvertere Swift billede")
        }
        
        // When
        let imageId = UUID().uuidString + ".png" // Unik filsti for hvert test run
        let storageRef = storage.reference().child("test_images/\(imageId)")
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        
        // Then
        #expect(!downloadURL.absoluteString.isEmpty)
    }
    
    // MARK: - User Story 10: Login persistence
    @Test
    func loginPersistence() async throws {
        // Given
        let email = "persistence@swift.com"
        let password = "swiftPersistence123"
        
        // Forsøg at oprette bruger, ignorer fejl hvis bruger eksisterer
        do {
            let _ = try await auth.createUser(withEmail: email, password: password)
        } catch let error as NSError {
            // Kun log fejlen hvis det ikke er fordi brugeren allerede findes
            if error.code != 17007 { // ERROR_EMAIL_ALREADY_IN_USE kode
                print("Fejl ved oprettelse: \(error.localizedDescription)")
            }
        }
        
        // When
        _ = try await auth.signIn(withEmail: email, password: password)
        
        // Then
        #expect(auth.currentUser?.email == email)
    }
    
    // MARK: - User Story 4: Søgning
    @Test
    func searchTools() async throws {
        // Given
        let testId = "testHammer"
        let testData: [String: Any] = [
            "name": "Hammer",
            "description": "En stor hammer",
            "ownerUID": "test",
            "pricePerDay": 0,
            "category": "Test",
            "isOnHold": false,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // When
        try await db.collection("tools").document(testId).setData(testData)
        
        // Then
        let doc = try await db.collection("tools").document(testId).getDocument()
        #expect(doc.exists)
        #expect(doc.get("name") as? String == "Hammer")
    }
    
    // MARK: - User Story 6: Rediger profil
    @Test
    func updateUserProfile() async throws {
        // Given
        let uniqueEmail = "updateuserprofile_\(Date().timeIntervalSince1970)@test.com"
        let password = "test123"
        
        // Opret bruger
        var userUID = ""
        do {
            let user = try await auth.createUser(withEmail: uniqueEmail, password: password)
            userUID = user.user.uid
        } catch let error {
            print("Fejl ved brugeroprettelse: \(error.localizedDescription)")
            throw error
        }
        
        //When
        try await db.collection("users").document(userUID).setData([
            "initialized": true,
            "name": "Test Navn",
            "email": uniqueEmail
        ])
        
        // Then
        let userDoc = try await db.collection("users").document(userUID).getDocument()
        #expect(userDoc.exists)
        #expect(userDoc.get("name") as? String == "Test Navn")
    }
    
    // MARK: - User Story 7: Sortering
    @Test
    func sortTools() async throws {
        // Given
        let testTools = [
            Tool(
                id: "1",
                name: "B",
                description: "Test",
                imageURL: nil,
                ownerUID: "test",
                pricePerDay: 0,
                category: "Test",
                isOnHold: false,
                timestamp: Date().addingTimeInterval(-3600) // Ældre dato
            ),
            Tool(
                id: "2",
                name: "A",
                description: "Test",
                imageURL: nil,
                ownerUID: "test",
                pricePerDay: 0,
                category: "Test",
                isOnHold: false,
                timestamp: Date() // Nyere dato
            )
        ]
        
        // When
        let sortedByName = testTools.sorted { $0.name < $1.name }
        let sortedByDate = testTools.sorted { 
            ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) 
        }
        
        // Then
        #expect(sortedByName.first?.name == "A")
        #expect(sortedByDate.first?.name == "A") // Forventer nyeste først
    }
    
    // MARK: - User Story 9: Offline funktion
    @Test
    func offlineDataAccess() async throws {
        let settings = Firestore.firestore().settings
        #expect(settings.isPersistenceEnabled == true)
    }
    
    // MARK: - User Story 11: Skift forening
    @Test
    func updateUserAssociation() async throws {
        // Given
        let originalCategory = "OriginalKategori_\(UUID().uuidString)"
        let newCategory = "NyKategori_\(UUID().uuidString)"
        let toolId = UUID().uuidString
        
        // Opret testværktøj direkte i DB
        try await db.collection("tools").document(toolId).setData([
            "category": originalCategory,
            "name": "TestVærktøj",
            "description": "Testbeskrivelse",
            "ownerUID": "testBruger",
            "pricePerDay": 0,
            "isOnHold": false,
            "timestamp": FieldValue.serverTimestamp()
        ])
        
        // When
        try await db.collection("tools").document(toolId).updateData(["category": newCategory])
        
        // Then
        let updatedDoc = try await db.collection("tools").document(toolId).getDocument()
        #expect(updatedDoc.get("category") as? String == newCategory)
    }
    
    // MARK: - User Story 12: Slet profil
    @Test
    func deleteUserAccount() async throws {
        // Generer unik e-mail
        let uniqueEmail = "delete_\(Date().timeIntervalSince1970)@test.com"
        
        // Given - opret bruger
        var userUID = ""
        do {
            let user = try await auth.createUser(withEmail: uniqueEmail, password: "test123")
            userUID = user.user.uid
            
            // Opret brugerdokument
            try await db.collection("users").document(userUID).setData([
                "email": uniqueEmail,
                "name": "Slet mig"
            ])
        } catch {
            print("Fejl ved brugeroprettelse: \(error.localizedDescription)")
            throw error
        }
        
        // When - slet bruger dokument direkte
        try await db.collection("users").document(userUID).delete()
        
        // Then
        let deletedDoc = try? await db.collection("users").document(userUID).getDocument()
        #expect(!deletedDoc!.exists)
    }
    
    // fejlhåndtering
    struct TestError: Error, CustomStringConvertible {
        let description: String
        init(_ description: String) { self.description = description }
    }
}
