import Foundation

// Model for brugerinformation
struct UserInfo: Identifiable {
    let id: String
    let name: String
    let email: String
    let phoneNumber: String?
    let address: String?
    let association: String
} 