import Foundation

enum SupabaseError: Error {
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case invalidURL
}

class SupabaseService {
    static let shared = SupabaseService()
    private let baseURL: String
    private let apiKey: String
    
    private init() {
        self.baseURL = AppEnvironment.supabaseURL
        self.apiKey = AppEnvironment.supabaseAnonKey
    }
    
    private func createRequest(_ path: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(baseURL)/rest/v1/\(path)")!)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.httpBody = body
        return request
    }
    
    // Save or update user profile
    func saveUserProfile(_ user: User) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let userData = try encoder.encode(user)
        print("Attempting to save user data: \(String(data: userData, encoding: .utf8) ?? "invalid data")")
        
        // Check if user exists first
        let existingUser = try? await fetchUserProfile(id: user.id)
        let method = existingUser == nil ? "POST" : "PATCH"
        let path = existingUser == nil ? "profiles" : "profiles?id=eq.\(user.id.uuidString)"
        
        let request = createRequest(
            path,
            method: method,
            body: userData
        )
        print("Request URL: \(request.url?.absoluteString ?? "none")")
        print("Request method: \(method)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            print("Failed to save user profile. Status code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
            if let errorData = String(data: data, encoding: .utf8) {
                print("Error response: \(errorData)")
            }
            throw SupabaseError.invalidResponse
        }
        
        // Save user ID to UserDefaults for later retrieval
        UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserId")
    }
    
    // Fetch user profile
    func fetchUserProfile(id: UUID) async throws -> User {
        let request = createRequest("profiles?id=eq.\(id.uuidString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let users = try decoder.decode([User].self, from: data)
        guard let user = users.first else {
            throw SupabaseError.invalidResponse
        }
        
        return user
    }
    
    // Save nutrition plan
    func saveNutritionPlan(_ plan: NutritionPlan) async throws {
        let encoder = JSONEncoder()
        let planData = try encoder.encode(plan)
        
        let request = createRequest(
            "nutrition_plans",
            method: "POST",
            body: planData
        )
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw SupabaseError.invalidResponse
        }
    }
    
    // Fetch user's nutrition plans
    func fetchNutritionPlans(userId: UUID) async throws -> [NutritionPlan] {
        let request = createRequest("nutrition_plans?user_id=eq.\(userId.uuidString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([NutritionPlan].self, from: data)
    }
    
    func getCurrentUser() async throws -> User? {
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId"),
              let id = UUID(uuidString: userId) else {
            return nil
        }
        return try await fetchUserProfile(id: id)
    }
    
    func testConnection() async throws -> Bool {
        // Test connection by checking for profiles table
        let request = createRequest("profiles")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            print("Supabase Connection Test - Status Code: \(httpResponse.statusCode)")
            print("Supabase URL being used: \(baseURL)")
            print("Full request URL: \(request.url?.absoluteString ?? "none")")
            
            // 200 = success, 401 = unauthorized (but connection works)
            return httpResponse.statusCode == 200 || httpResponse.statusCode == 401
        } catch {
            print("Supabase Connection Test Failed - Error: \(error.localizedDescription)")
            throw SupabaseError.networkError(error)
        }
    }
} 