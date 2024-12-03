import Foundation

// Manager til lokal cache af værktøjer og brugerinformation
class LocalCacheManager {
    static let shared = LocalCacheManager() // Singleton instans

    // MARK: - Variabler
    private let toolsKey = "cachedTools"
    private let userInfoKey = "cachedUserInfo"
    private let associationsKey = "cachedAssociations"

    // MARK: - Init
    private init() {}

    // MARK: - Tools
    /// Gemmer en liste af værktøjer. Kaldes, når vi modtager nye data fra Firestore.
    func saveTools(_ tools: [Tool]) {
        do {
            let data = try JSONEncoder().encode(tools)
            UserDefaults.standard.set(data, forKey: toolsKey)
        } catch {
            print("Failed to save tools to cache: \(error.localizedDescription)")
        }
    }

    /// Læser værktøjer fra lokal cache. Bruges ved offline-scenarier.
    func loadTools() -> [Tool] {
        guard let data = UserDefaults.standard.data(forKey: toolsKey) else { return [] }
        do {
            return try JSONDecoder().decode([Tool].self, from: data)
        } catch {
            print("Failed to load tools from cache: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - User Info
    /// Gemmer den aktuelle brugers oplysninger lokalt
    func saveUserInfo(_ userInfo: UserInfo) {
        do {
            let data = try JSONEncoder().encode(userInfo)
            UserDefaults.standard.set(data, forKey: userInfoKey)
        } catch {
            print("Failed to save user info to cache: \(error.localizedDescription)")
        }
    }

    /// Henter brugernes data fra lokal cache (fx hvis ingen internetforbindelse)
    func loadUserInfo() -> UserInfo? {
        guard let data = UserDefaults.standard.data(forKey: userInfoKey) else { return nil }
        do {
            return try JSONDecoder().decode(UserInfo.self, from: data)
        } catch {
            print("Failed to load user info from cache: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Associations
    /// Gemmer navne på foreninger. Bruges efter succesfuldt Firestore-kald.
    func saveAssociations(_ associations: [String]) {
        UserDefaults.standard.set(associations, forKey: associationsKey)
    }

    /// Henter foreningsnavne fra cachen, hvis ingen forbindelse til Firestore.
    func loadAssociations() -> [String] {
        UserDefaults.standard.stringArray(forKey: associationsKey) ?? []
    }

    /// Returnerer true, hvis der allerede ligger foreningsnavne i cachen.
    func hasCachedAssociations() -> Bool {
        let list = loadAssociations()
        return !list.isEmpty
    }
}
