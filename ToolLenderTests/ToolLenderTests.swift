//
//  ToolLenderTests.swift
//  ToolLenderTests
//
//  Created by Tobias Schwartzlose on 03/12/2024.
//

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
            
            // Konfigurer emulator FØR initialisering af services
            let firestore = Firestore.firestore()
            firestore.useEmulator(withHost: "localhost", port: 8080)
            
            Auth.auth().useEmulator(withHost: "localhost", port: 9099)
            Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        }
        
        // Initialiser services EFTER emulator konfiguration
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
        
        // When
        let user = try await auth.signIn(withEmail: email, password: password)
        
        // Then
        #expect(user.user.email == email)
    }
    
    // MARK: - User Story 2: Værktøjsliste
    @Test
    func fetchTools() async throws {
        // Given
        let testData: [String: Any] = [
            "id": "swiftTest123",
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
        try await db.collection("tools").document(testData["id"] as! String).setData(testData)
        let tools = try await toolHandler.fetchToolsByOwner(ownerUID: "swiftTester")
        
        // Then
        #expect(!tools.isEmpty)
        #expect(tools.first?.name == "Swift Test Værktøj")
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
        let testData: [String: Any] = [
            "id": "swiftPauseTest",
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
        try await db.collection("tools").document(testData["id"] as! String).setData(testData)
        let initialTool = Tool(
            id: testData["id"] as! String,
            name: testData["name"] as! String,
            description: testData["description"] as! String,
            imageURL: testData["imageURL"] as? String,
            ownerUID: testData["ownerUID"] as! String,
            pricePerDay: testData["pricePerDay"] as? Double,
            category: testData["category"] as! String,
            isOnHold: testData["isOnHold"] as! Bool,
            timestamp: (testData["timestamp"] as! Timestamp).dateValue()
        )
        try await toolHandler.toggleHoldStatus(for: initialTool)
        
        // Then
        let updatedDoc = try await db.collection("tools").document(initialTool.id).getDocument()
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
        let storageRef = storage.reference().child("swiftTestImage.png")
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
        //_ = try await auth.createUser(withEmail: email, password: password)
        
        // When
        try await auth.signIn(withEmail: email, password: password)
        
        // Then
        #expect(auth.currentUser != nil)
        #expect(auth.currentUser?.email == email)
    }
    
    // MARK: - User Story 4: Søgning
    @Test
    func searchTools() async throws {
        // Given
        let searchTerm = "Hammer"
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
        try await db.collection("tools").document("testHammer").setData(testData)
        let results = try await toolHandler.fetchAllTools()
            .filter { $0.name.localizedCaseInsensitiveContains(searchTerm) }
        
        // Then
        #expect(!results.isEmpty)
        #expect(results.first?.name == "Hammer")
    }
    
    // MARK: - User Story 6: Rediger profil
    @Test
    func updateUserProfile() async throws {
        // Given
        let uniqueEmail = "updateuserprofile@test.com"
        let password = "test123"
        
        // Opret bruger OG brugerdokument
        let user = try await auth.signIn(withEmail: uniqueEmail, password: password)
        try await userHandler.updateUserFields(
            userUID: user.user.uid, 
            updates: ["initialized": true] // Opret dokumentet
        )
        
        let newName = "Nyt Navn"
        
        // When
        try await userHandler.updateUserFields(
            userUID: user.user.uid, 
            updates: ["name": newName]
        )
        
        // Then
        let updatedData = try await userHandler.fetchUserData(userUID: user.user.uid)
        #expect(updatedData?["name"] as? String == newName)
        
        // Oprydning
        try await userHandler.deleteUser(userUID: user.user.uid)
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
        // Given
        try await db.disableNetwork()
        defer { db.enableNetwork() }
        
        // When
        let tools = try await toolHandler.fetchAllTools()
        
        // Then
        #expect(!tools.isEmpty)
    }
    
    // MARK: - User Story 11: Skift forening
    @Test
    func updateUserAssociation() async throws {
        // Given
        let originalCategory = "OriginalKategori_\(UUID().uuidString)"
        let newCategory = "NyKategori_\(UUID().uuidString)"
        
        // Opret testværktøj
        let tool = Tool(
            id: UUID().uuidString,
            name: "TestVærktøj",
            description: "Testbeskrivelse",
            imageURL: nil,
            ownerUID: "testBruger",
            pricePerDay: 0,
            category: originalCategory,
            isOnHold: false,
            timestamp: Date()
        )
        
        try await db.collection("tools").document(tool.id).setData([
            "category": originalCategory,
            "name": tool.name,
            "description": tool.description,
            "ownerUID": tool.ownerUID,
            "pricePerDay": tool.pricePerDay ?? 0,
            "isOnHold": tool.isOnHold,
            "timestamp": FieldValue.serverTimestamp()
        ])
        
        // When
        try await db.collection("tools").document(tool.id).updateData(["category": newCategory])
        
        // Then
        let updatedDoc = try await db.collection("tools").document(tool.id).getDocument()
        #expect(updatedDoc.get("category") as? String == newCategory)
        
        // Oprydning
        try await db.collection("tools").document(tool.id).delete()
    }
    
    
    // MARK: - User Story 12: Slet profil
    @Test
    func deleteUserAccount() async throws {
        // Generer unik e-mail
        let uniqueEmail = "delete_\(Date().timeIntervalSince1970)@test.com"
        
        // Given
        let user = try await auth.createUser(withEmail: uniqueEmail, password: "test123")
        
        // When
        try await userHandler.deleteUser(userUID: user.user.uid)
        let deletedUser = try? await userHandler.fetchUserData(userUID: user.user.uid)
        
        // Then
        #expect(deletedUser == nil)
        try await userHandler.deleteUser(userUID: user.user.uid)
    }
    
    
    
    // Hjælpe struct til fejlhåndtering
    struct TestError: Error, CustomStringConvertible {
        let description: String
        init(_ description: String) { self.description = description }
    }
}
