
import FirebaseRemoteConfig
import FirebaseCore
import FHKDomain
import FHKUtils

@MainActor
public final class FHKRemoteConfigService: FHKRemoteConfigManagerProtocol {
    public let remoteConfig: RemoteConfig
    public var enabledLanguages: [String] = []
    
    
    // MARK: - Inicialización
    public init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Logger.info("FirebaseApp configurado desde FHKConfig.")
        }
        
        remoteConfig = RemoteConfig.remoteConfig()
        setupSettings()
    }
    
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
    }
    
    // MARK: - Obtener Lenguajes
    private func getEnabledLanguages() -> [String] {
        let configValue = remoteConfig.configValue(forKey: "enabled_languages")
        
        // Obtenemos el valor (Firebase devuelve "" si no existe, no nil)
        let jsonString = configValue.stringValue
        
        // 2. Comprobamos que no esté vacío
        guard !jsonString.isEmpty else {
            Logger.error("Error: El valor de 'enabled_languages' en Firebase está vacío.")
            return ["es"]
        }
        
        // Convertimos a Data
        guard let jsonData = jsonString.data(using: .utf8) else {
            Logger.error("Error: No se pudo convertir el string de Firebase a Data.")
            return ["es"]
        }
        
        do {
            let languageStatus = try JSONDecoder().decode(LanguageModel.self, from: jsonData)
            return languageStatus.enabledCodes
        } catch {
            Logger.error("Error al decodificar JSON de Remote Config: \(error)")
            return ["es"]
        }
    }
}
