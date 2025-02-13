import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct UploadToolView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var userAssociation: String
    
    @State private var toolName: String = ""
    @State private var toolDescription: String = ""
    @State private var pricePerDay: String = ""
    @State private var selectedImageData: Data? = nil
    @State private var imageUrl: String? = nil
    @State private var errorMessage: String = ""
    @State private var showImagePicker: Bool = false
    @State private var isLoading: Bool = false
    @State private var categories: [String] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Button(action: { showImagePicker = true }) {
                        ZStack {
                            if let imageData = selectedImageData, 
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .cornerRadius(12)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.title)
                                            Text("Add Photo")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.blue)
                                    )
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        TextField("Tool Name", text: $toolName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        TextField("Description", text: $toolDescription)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        TextField("Price per Day (DKK)", text: $pricePerDay)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Assocation")
                            .font(.headline)
                        Spacer()
                        Menu {
                            ForEach(categories, id: \.self) { category in
                                Button(category) {
                                    userAssociation = category
                                }
                            }
                        } label: {
                            HStack {
                                Text(userAssociation)
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    Button(action: uploadTool) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                                Text("Upload Tool")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("New Tool")
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    selectedImageData = image.jpegData(compressionQuality: 0.8)
                }
            }
            .task {
                do {
                    self.categories = try await AssociationHandler.shared.fetchAssociations(insertAllAtTop: false)
                } catch {
                    print("Error loading categories: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func uploadTool() {
        guard validateInputs() else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let imageUrl = try await uploadImage()
                try await saveToolToFirebase(imageUrl: imageUrl)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func validateInputs() -> Bool {
        guard !toolName.isEmpty else {
            errorMessage = "Please enter a tool name"
            return false
        }
        guard !toolDescription.isEmpty else {
            errorMessage = "Please enter a description"
            return false
        }
        return true
    }
    
    private func uploadImage() async throws -> String? {
        guard let imageData = selectedImageData else { return nil }
        let storageRef = Storage.storage().reference()
        let imageName = UUID().uuidString
        let imageRef = storageRef.child("toolImages/\(imageName).jpg")
        
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
    
    private func saveToolToFirebase(imageUrl: String?) async throws {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        
        let toolData: [String: Any] = [
            "name": toolName,
            "description": toolDescription,
            "pricePerDay": Double(pricePerDay) ?? 0.0,
            "imageURL": imageUrl ?? "",
            "ownerUID": userUID,
            "category": userAssociation,
            "timestamp": Timestamp(date: Date()),
            "isOnHold": false
        ]
        
        let db = Firestore.firestore()
        try await db.collection("tools").addDocument(data: toolData)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, 
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
