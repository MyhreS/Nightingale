import Foundation

class SecretsKeeper {
    static let shared = SecretsKeeper()
    
    init () {
        
    }
    
    private lazy var clientID: String = loadInfoValue("SOUND_CLOUD_CLIENT_ID")
    
    private lazy var clientSecret: String = loadInfoValue("SOUND_CLOUD_CLIENT_SECRET")
    
    private lazy var redirectURI: String = loadInfoValue("REDIRECT_URI")
    
    func loadInfoValue(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            print("SecretsKeeper: Missing Info.plist key: \(key)")
            return ""
        }
        return value
    }
    
    func getClientId() -> String {
        clientID
    }
    
    func getClientSecret() -> String { clientSecret }
    
    func getRedirectUri() -> String {redirectURI}
    
}
