
import FirebaseRemoteConfig
import FirebaseCore
import FHKDomain
import FHKUtils

@MainActor
public extension FHKRemoteConfig {
    static var live: Self {
        let state = LiveState()
        
        var config = Self()
        
        config.enabledLanguages = { state.getEnabledLanguages() }
        config.menuHomeItems = { state.getMenuHomeItems() }
        
        config.fetchConfig = { try await state.fetchConfig() }
        config.getCachedTimeExpiration = { await state.getCachedTimeExpiration() }
        
        return config
    }
}

private final class LiveState: @unchecked Sendable {
    private let lock = NSLock()
    private let remoteConfig: RemoteConfig
    
    private var _enabledLanguages: [String] = []
    private var _menuHomeItems: [MenuHomeItem] = []
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Logger.info("FirebaseApp configurado desde FHKConfig.")
        }
        
        self.remoteConfig = RemoteConfig.remoteConfig()
        self.setupSettings()
    }
    
    // MARK: - Getters Públics (async and secure)
    func getEnabledLanguages() -> [String] {
        lock.withLock {
            return _enabledLanguages
        }
    }
    
    func getMenuHomeItems() -> [MenuHomeItem] {
        lock.withLock {
            return _menuHomeItems
        }
    }
    
    // MARK: - Async Operations
    func fetchConfig() async throws {
        let status = try await remoteConfig.fetchAndActivate()
        
        switch status {
        case .successFetchedFromRemote:
            Logger.info("✅ Firebase: Fresh data downloaded.")
        case .successUsingPreFetchedData:
            Logger.info("🏠 Firebase: Using local cache data.")
        case .error:
            Logger.error("❌ Firebase: Network error or throttling.")
        @unknown default:
            break
        }
        
        // Proccesing Data
        let freshLanguages = self.parseEnabledLanguages()
        let freshMenuItems = self.parseMenuOptionsHome()
        
        // We securely store it in the cache within the lock.
        lock.withLock {
            self._enabledLanguages = freshLanguages
            self._menuHomeItems = freshMenuItems
        }
    }
    
    func getCachedTimeExpiration() async -> Int {
        let defaultValue: Int = 3 // minutes
        do {
            _ = try await remoteConfig.fetchAndActivate()
            let configValue = remoteConfig.configValue(forKey: "cached_time_expiration")
            let value = configValue.numberValue.intValue
            return value > 0 ? value : defaultValue
        } catch {
            Logger.error("Error Getting cached_time_expiration from Remote Config: \(error)")
            return defaultValue
        }
    }
}

private extension LiveState {
    
    func setupSettings() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 7200
        #endif
        remoteConfig.configSettings = settings
        
        let defaultValues: [String: NSObject] = [
            "enabled_languages": "{\"es\": true, \"fr\": true, \"en\": true, \"it\": true}" as NSObject
        ]
        remoteConfig.setDefaults(defaultValues)
    }
    
    func parseEnabledLanguages() -> [String] {
        let defaultModel = LanguageModel()
        let languageStatus = fetchAndDecodeRemoteConfig(forKey: "enabled_languages",
                                                       defaultValue: defaultModel)
        return languageStatus.enabledCodes
    }

    func parseMenuOptionsHome() -> [MenuHomeItem] {
        return fetchAndDecodeRemoteConfig(forKey: "menus_bottom_bar_enables",
                                         defaultValue: [])
    }
    
    func fetchAndDecodeRemoteConfig<T: Decodable>(forKey key: String, defaultValue: T) -> T {
        let configValue = remoteConfig.configValue(forKey: key)
        let jsonString = configValue.stringValue
        
        guard !jsonString.isEmpty else {
            Logger.error("Error: the value of '\(key)' en Firebase está vacío.")
            return defaultValue
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            Logger.error("Error: Can't converter the string of '\(key)' a Data.")
            return defaultValue
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            Logger.error("Error to decodificate JSON of '\(key)' in Remote Config: \(error)")
            return defaultValue
        }
    }
}
