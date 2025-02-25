import Foundation

// MARK: - API Response Types
struct DeepSeekResponse: Codable {
    struct Message: Codable {
        let content: String
    }
    
    struct Choice: Codable {
        let message: Message
    }
    
    let choices: [Choice]
}

// MARK: - API Request Types
struct DeepSeekRequest: Codable {
    let model: String
    let messages: [Message]
    
    struct Message: Codable {
        let role: String
        let content: String
    }
} 