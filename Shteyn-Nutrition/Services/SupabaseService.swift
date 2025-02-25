import Foundation

enum SupabaseError: Error {
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case invalidURL
    case requestFailed
}

class SupabaseService {
    static let shared = SupabaseService()
    private let baseURL: String
    private let apiKey: String
    
    // Add current user ID storage
    private var currentUserId: UUID? {
        get {
            if let uuidString = UserDefaults.standard.string(forKey: "currentUserId") {
                return UUID(uuidString: uuidString)
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: "currentUserId")
        }
    }
    
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
        
        // Store the user ID
        currentUserId = user.id
        
        let path = "profiles?id=eq.\(user.id.uuidString)"
        var request = createRequest(
            path,
            method: "UPSERT", // Use UPSERT to handle both insert and update
            body: userData
        )
        
        // Add Prefer header for upsert
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Error saving profile: \(errorData)")
            }
            throw SupabaseError.invalidResponse
        }
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
        // First check if we have a stored user ID
        guard let userId = currentUserId else {
            // If no stored ID, create a new user
            let newUser = User(
                id: UUID(),
                name: "New User",
                age: 30,
                weight: 70,
                height: 170,
                gender: .male,
                activityLevel: .moderatelyActive,
                nutritionGoal: .maintenance,
                preferredUnits: .imperial
            )
            try await saveUserProfile(newUser)
            currentUserId = newUser.id
            return newUser
        }
        
        // Try to fetch existing user
        let request = createRequest("profiles?id=eq.\(userId.uuidString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let users = try JSONDecoder().decode([User].self, from: data)
            if let user = users.first {
                return user
            }
        }
        
        // If user not found, clear stored ID and create new user
        currentUserId = nil
        return try await getCurrentUser()
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
