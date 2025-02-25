import Foundation

enum DeepSeekError: Error {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
}

class DeepSeekService {
    static let shared = DeepSeekService()
    private let apiKey: String
    
    private init() {
        self.apiKey = AppEnvironment.deepseekAPIKey
    }
    
    func generateNutritionPlan(for user: User) async throws -> NutritionPlan {
        let prompt = """
        Generate a personalized nutrition plan for:
        - Age: \(user.age)
        - Weight: \(Int(user.weightInPounds)) lbs
        - Height: \(user.heightFeet)'\(user.heightInches)"
        - Gender: \(user.gender.rawValue)
        - Activity Level: \(user.activityLevel.rawValue)
        - Goal: \(user.nutritionGoal.rawValue)
        
        Include daily calorie target, macronutrient breakdown, and 3 meal suggestions with ingredients.
        Format as JSON matching the NutritionPlan model structure.
        """
        
        var request = URLRequest(url: URL(string: "https://api.deepseek.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DeepSeekError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let aiResponse = try decoder.decode(DeepSeekResponse.self, from: data)
        let nutritionPlanData = Data(aiResponse.choices[0].message.content.utf8)
        return try decoder.decode(NutritionPlan.self, from: nutritionPlanData)
    }
    
    func getAIRecommendations(user: User, currentPlan: NutritionPlan) async throws -> String {
        let prompt = """
        Analyze this nutrition plan and provide personalized recommendations for:
        - Age: \(user.age)
        - Weight: \(Int(user.weightInPounds)) lbs
        - Height: \(user.heightFeet)'\(user.heightInches)"
        - Goal: \(user.nutritionGoal.rawValue)
        
        Current plan:
        - Daily calories: \(currentPlan.dailyCalories)
        - Protein: \(currentPlan.macronutrients["protein"] ?? 0)g
        - Carbs: \(currentPlan.macronutrients["carbs"] ?? 0)g
        - Fats: \(currentPlan.macronutrients["fats"] ?? 0)g
        
        Provide specific recommendations for improving the plan and achieving the user's goals.
        """
        
        var request = URLRequest(url: URL(string: "https://api.deepseek.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DeepSeekError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let aiResponse = try decoder.decode(DeepSeekResponse.self, from: data)
        return aiResponse.choices[0].message.content
    }
} 