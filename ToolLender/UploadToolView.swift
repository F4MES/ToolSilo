import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct UploadToolView: View {
    @State private var toolName = ""
    @State private var toolDescription = ""
    @State private var pricePerDay: String = ""
    @State private var selectedImageData: Data? = nil
    @State private var imageUrl: String? = nil
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    @Binding var userAssociation: String
    @State private var associations: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            TextField("Item Name", text: $toolName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Item Description", text: $toolDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Price/Day", text: $pricePerDay)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.decimalPad)

            Text("Association")
                .font(.headline)
                .padding(.top)

            Picker("Select Association", selection: $userAssociation) {
                ForEach(associations, id: \.self) { association in
                    Text(association)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                PhotosPicker(selection: Binding(get: { nil }, set: { loadImage($0) }), matching: .images) {
                    Text("Select Image (Optional)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if let link = imageUrl {
                Text("Image URL: \(link)")
                    .foregroundColor(.green)
                    .padding()
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Add Item") {
                Task {
                    await uploadTool()
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(toolName.isEmpty || toolDescription.isEmpty)

            Spacer()
        }
        .padding()
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Your item has been uploaded successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            Task {
                await loadAssociations()
            }
        }
    }

    private func loadImage(_ pickerItem: PhotosPickerItem?) {
        guard let pickerItem = pickerItem else { return }
        pickerItem.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    self.selectedImageData = image.jpegData(compressionQuality: 0.8)
                }
            case .failure(let error):
                errorMessage = "Failed to load image: \(error.localizedDescription)"
            }
        }
    }

    private func uploadTool() async {
        guard !toolName.isEmpty, !toolDescription.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to upload."
            return
        }

        let price = Double(pricePerDay) ?? 0.0
        if let imageData = selectedImageData {
            if let urlString = await uploadImageToFirebaseStorage(imageData) {
                saveToolToFirestore(imageURL: urlString, price: price, ownerUID: currentUser.uid, category: userAssociation)
            } else {
                errorMessage = "Failed to upload image to Firebase Storage."
            }
        } else {
            saveToolToFirestore(imageURL: nil, price: price, ownerUID: currentUser.uid, category: userAssociation)
        }
    }

    private func saveToolToFirestore(imageURL: String?, price: Double, ownerUID: String, category: String) {
        let db = Firestore.firestore()
        let toolData: [String: Any] = [
            "name": toolName,
            "description": toolDescription,
            "imageURL": imageURL ?? "",
            "ownerUID": ownerUID,
            "pricePerDay": price,
            "category": category,
            "timestamp": Timestamp()
        ]

        db.collection("tools").addDocument(data: toolData) { error in
            if let error = error {
                errorMessage = "Failed to save item: \(error.localizedDescription)"
            } else {
                toolName = ""
                toolDescription = ""
                pricePerDay = ""
                selectedImageData = nil
                imageUrl = nil
                showSuccessAlert = true
                
                Task {
                    await ToolHandler.shared.fetchAllToolsCachedFirst()
                }
            }
        }
    }

    private func uploadImageToFirebaseStorage(_ imageData: Data) async -> String? {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let uniqueFileName = UUID().uuidString
        let imageRef = storageRef.child("images/\(uniqueFileName).jpg")

        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            try await imageRef.putDataAsync(imageData, metadata: metadata)
            let url = try await imageRef.downloadURL()
            return url.absoluteString
        } catch {
            print("Image upload failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func loadAssociations() async {
        do {
            self.associations = try await AssociationHandler.shared.fetchAssociations(insertAllAtTop: false)
        } catch {
            print("Error fetching associations: \(error.localizedDescription)")
            self.associations = LocalCacheManager.shared.loadAssociations()
        }
    }
}
