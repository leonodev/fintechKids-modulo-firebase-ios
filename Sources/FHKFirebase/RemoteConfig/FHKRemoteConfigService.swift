
import FirebaseRemoteConfig
import FirebaseCore
import FHKDomain
import FHKUtils

@MainActor
public final class FHKRemoteConfigService: FHKRemoteConfigManagerProtocol {
    public let remoteConfig: RemoteConfig
    public var enabledLanguages: [String] = []
    public var menuHomeItems: [MenuHomeItem] = []
    
    // MARK: - Inicialización
    public init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Logger.info("FirebaseApp configurado desde FHKConfig.")
        }
        
        remoteConfig = RemoteConfig.remoteConfig()
        setupSettings()
    }
    
    public func fetchConfig() async throws {
        let status = try await remoteConfig.fetchAndActivate()
        
        switch status {
        case .successFetchedFromRemote:
            Logger.info("✅ Firebase: Datos frescos descargados.")
        case .successUsingPreFetchedData:
            Logger.info("🏠 Firebase: Usando datos de la caché local.")
        case .error:
            Logger.error("❌ Firebase: Error en la red o Throttling.")
        @unknown default:
            break
        }
        
        self.enabledLanguages = self.getEnabledLanguages()
        self.menuHomeItems = self.getMenuOptionsHome()
    }
    
    public func getCachedTimeExpiration() async -> Int {
        let defaultValue: Int = 3 // minutes
        do {
            // We tried to refresh the server values
            let _ = try await remoteConfig.fetchAndActivate()
            let configValue = remoteConfig.configValue(forKey: "cached_time_expiration")
            
            let value = configValue.numberValue.intValue
            return value > 0 ? value : defaultValue
        } catch {
            Logger.error("Error Getting cached_time_expiration from Remote Config: \(error)")
            return defaultValue
        }
    }
}

private extension FHKRemoteConfigService {
    
    private func setupSettings() {
        let settings = RemoteConfigSettings()
        
        #if DEBUG
        // fetch immediately in develop
        settings.minimumFetchInterval = 0
        #else
        // fetch each two hours in production
        settings.minimumFetchInterval = 7200
        #endif
        
        remoteConfig.configSettings = settings
        
        // Definimos los valores por defecto
        let defaultValues: [String: NSObject] = [
            "enabled_languages": "{\"es\": true, \"fr\": true, \"en\": true, \"it\": true}" as NSObject
        ]

        // Los registramos en Remote Config
        remoteConfig.setDefaults(defaultValues)
    }
    
    // MARK: - get language
    private func getEnabledLanguages() -> [String] {
        let defaultModel = LanguageModel()
        let languageStatus = fetchAndDecodeRemoteConfig(forKey: "enabled_languages",
                                                        defaultValue: defaultModel)
        return languageStatus.enabledCodes
    }

    // MARK: - get menus by home
    private func getMenuOptionsHome() -> [MenuHomeItem] {
        return fetchAndDecodeRemoteConfig(forKey: "menus_bottom_bar_enables", defaultValue: [])
    }
    
    private func fetchAndDecodeRemoteConfig<T: Decodable>(forKey key: String, defaultValue: T) -> T {
        let configValue = remoteConfig.configValue(forKey: key)
        let jsonString = configValue.stringValue
        
        // check not empty
        guard !jsonString.isEmpty else {
            Logger.error("Error: El valor de '\(key)' en Firebase está vacío.")
            return defaultValue
        }
        
        // converte to Data
        guard let jsonData = jsonString.data(using: .utf8) else {
            Logger.error("Error: No se pudo convertir el string de '\(key)' a Data.")
            return defaultValue
        }
        
        // We decode the generic type T
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: jsonData)
            return decodedData
        } catch {
            Logger.error("Error al decodificar JSON de '\(key)' en Remote Config: \(error)")
            return defaultValue
        }
    }
}
