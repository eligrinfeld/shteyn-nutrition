import Foundation

enum DeepSeekError: Error {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case parsingError(String)
}

class DeepSeekService {
    static let shared = DeepSeekService()
    private let apiKey: String
    
    private init() {
        self.apiKey = AppEnvironment.deepseekAPIKey
    }
    
    private func cleanJSONResponse(_ response: String) -> String {
        // Remove markdown code block markers if present
        var cleanResponse = response
        if response.hasPrefix("```json") {
            cleanResponse = String(response.dropFirst(7))
        }
        if cleanResponse.hasSuffix("```") {
            cleanResponse = String(cleanResponse.dropLast(3))
        }
        return cleanResponse.trimmingCharacters(in: .whitespacesAndNewlines)
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
        
        Return a JSON object with the following structure:
        {
            "daily_calories": number,
            "macronutrients": {
                "protein": number,
                "carbs": number,
                "fats": number
            },
            "meal_suggestions": [
                {
                    "meal": "string",
                    "suggestions": ["string"]
                }
            ]
        }
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
        let jsonString = cleanJSONResponse(aiResponse.choices[0].message.content)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw DeepSeekError.parsingError("Could not convert response to data")
        }
        
        do {
            // First decode to a temporary structure that matches the AI response
            struct AIResponse: Codable {
                let dailyCalories: Int
                let macronutrients: [String: Int]
                let mealSuggestions: [MealSuggestion]
                let recommendations: [String]
                
                enum CodingKeys: String, CodingKey {
                    case dailyCalories = "daily_calories"
                    case macronutrients
                    case mealSuggestions = "meal_suggestions"
                    case recommendations
                }
            }
            
            let aiPlan = try decoder.decode(AIResponse.self, from: jsonData)
            
            // Create NutritionPlan from AI response
            let nutritionPlan = NutritionPlan(
                id: UUID(),
                userId: user.id,
                dailyCalories: aiPlan.dailyCalories,
                macronutrients: aiPlan.macronutrients,
                mealSuggestions: aiPlan.mealSuggestions,
                recommendations: aiPlan.recommendations,
                createdAt: Date()
            )
            
            // Save to Supabase
            try await SupabaseService.shared.saveNutritionPlan(nutritionPlan)
            
            return nutritionPlan
        } catch {
            print("JSON parsing error: \(error)")
            print("Raw JSON string: \(jsonString)")
            throw DeepSeekError.parsingError("Failed to parse nutrition plan: \(error.localizedDescription)")
        }
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