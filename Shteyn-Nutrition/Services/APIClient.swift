import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let deepseekAPIKey = AppEnvironment.deepseekAPIKey
    private let supabaseURL = AppEnvironment.supabaseURL
    private let supabaseAnonKey = AppEnvironment.supabaseAnonKey
    
    private init() {}
    
    // Add your API methods here
} 