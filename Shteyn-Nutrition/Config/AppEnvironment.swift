import Foundation

enum AppEnvironment {
    enum Keys {
        static let deepseekAPIKey = "DEEPSEEK_API_KEY_PLIST"
        static let supabaseURL = "SUPABASE_URL_PLIST"
        static let supabaseAnonKey = "SUPABASE_ANON_KEY_PLIST"
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Info.plist file not found")
        }
        return dict
    }()
    
    static let deepseekAPIKey: String = {
        guard let key = infoDictionary[Keys.deepseekAPIKey] as? String else {
            fatalError("DeepSeek API Key not set in plist")
        }
        return key
    }()
    
    static let supabaseURL: String = {
        guard let url = infoDictionary[Keys.supabaseURL] as? String else {
            fatalError("Supabase URL not set in plist")
        }
        return url
    }()
    
    static let supabaseAnonKey: String = {
        guard let key = infoDictionary[Keys.supabaseAnonKey] as? String else {
            fatalError("Supabase Anon Key not set in plist")
        }
        return key
    }()
}
