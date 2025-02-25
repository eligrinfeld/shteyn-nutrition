import Foundation

// MARK: - NutritionPlanService
class NutritionPlanService {
    static let shared = NutritionPlanService()
    private let apiKey: String
    
    private init() {
        self.apiKey = AppEnvironment.deepseekAPIKey
    }
    
    func generateNutritionPlan(for user: User) async throws -> NutritionPlan {
        // Create prompt based on user profile
        let prompt = """
        As a nutrition expert, create a detailed nutrition plan in JSON format for a person with these characteristics:
        - Age: \(user.age)
        - Gender: \(user.gender)
        - Weight: \(user.preferredUnits == .imperial ? "\(Int(user.weightInPounds)) lbs" : "\(Int(user.weight)) kg")
        - Height: \(user.preferredUnits == .imperial ? "\(user.heightFeet)'\(user.heightInches)\"" : "\(Int(user.height)) cm")
        - Activity Level: \(user.activityLevel.rawValue)
        - Goal: \(user.nutritionGoal.rawValue)

        Return the response in this exact JSON format:
        {
            "daily_calories": number,
            "macronutrients": {
                "protein": number (in grams),
                "carbs": number (in grams),
                "fats": number (in grams)
            },
            "meal_suggestions": [
                {
                    "meal": "Breakfast",
                    "suggestions": ["suggestion1", "suggestion2", "suggestion3"]
                },
                {
                    "meal": "Lunch",
                    "suggestions": ["suggestion1", "suggestion2", "suggestion3"]
                },
                {
                    "meal": "Dinner",
                    "suggestions": ["suggestion1", "suggestion2", "suggestion3"]
                },
                {
                    "meal": "Snacks",
                    "suggestions": ["suggestion1", "suggestion2"]
                }
            ],
            "recommendations": [
                "recommendation1",
                "recommendation2",
                "recommendation3"
            ]
        }

        Base the calculations on the person's characteristics and these factors:
        1. BMR (Basal Metabolic Rate)
        2. Activity level multiplier
        3. Goal-specific adjustment
        4. Protein needs based on weight and activity
        5. Balanced macro distribution for the specific goal
        """
        
        // Call DeepSeek API
        let response = try await callDeepSeekAPI(with: prompt)
        
        // Print raw response for debugging
        print("DeepSeek Response: \(response)")
        
        // Parse response into NutritionPlan
        return try parseNutritionPlan(from: response, userId: user.id)
    }
    
    private func callDeepSeekAPI(with prompt: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.deepseek.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = DeepSeekRequest(
            model: "deepseek-chat",
            messages: [.init(role: "user", content: prompt)]
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NutritionPlanError.apiError
        }
        
        let result = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
    
    private func parseNutritionPlan(from response: String, userId: UUID) throws -> NutritionPlan {
        // Validate response is not empty
        guard !response.isEmpty else {
            throw NutritionPlanError.emptyResponse
        }
        
        // Try to parse JSON
        guard let jsonData = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NutritionPlanError.parsingError("Invalid JSON format")
        }
        
        // Validate required fields exist
        guard let dailyCalories = json["daily_calories"] as? Int,
              let macronutrients = json["macronutrients"] as? [String: Any],
              let mealSuggestions = json["meal_suggestions"] as? [[String: Any]],
              let recommendations = json["recommendations"] as? [String] else {
            throw NutritionPlanError.invalidResponse("Missing required fields")
        }
        
        // Validate and parse macronutrients
        guard let protein = macronutrients["protein"] as? Int,
              let carbs = macronutrients["carbs"] as? Int,
              let fats = macronutrients["fats"] as? Int else {
            throw NutritionPlanError.invalidMacronutrients("Missing or invalid macronutrient values")
        }
        
        let macros = [
            "protein": protein,
            "carbs": carbs,
            "fats": fats
        ]
        
        // Parse meal suggestions into MealSuggestion objects
        let mealSuggestionObjects = mealSuggestions.compactMap { mealDict -> MealSuggestion? in
            guard let meal = mealDict["meal"] as? String,
                  let suggestions = mealDict["suggestions"] as? [String] else {
                return nil
            }
            return MealSuggestion(id: UUID(), meal: meal, suggestions: suggestions)
        }
        
        // Ensure we have all required meals
        guard mealSuggestionObjects.count >= 3,
              mealSuggestionObjects.contains(where: { $0.meal == "Breakfast" }),
              mealSuggestionObjects.contains(where: { $0.meal == "Lunch" }),
              mealSuggestionObjects.contains(where: { $0.meal == "Dinner" }) else {
            throw NutritionPlanError.invalidMealSuggestions("Missing required meals")
        }
        
        // Validate daily calories
        guard dailyCalories >= 1200 && dailyCalories <= 5000 else {
            throw NutritionPlanError.invalidResponse("Daily calories out of reasonable range")
        }
        
        return NutritionPlan(
            id: UUID(),
            userId: userId,
            dailyCalories: dailyCalories,
            macronutrients: macros,
            mealSuggestions: mealSuggestionObjects,
            recommendations: recommendations,
            createdAt: Date()
        )
    }
}

// MARK: - Error Types
enum NutritionPlanError: Error {
    case apiError
    case parsingError(String)
    case invalidResponse(String)
    case invalidMacronutrients(String)
    case invalidMealSuggestions(String)
    case emptyResponse
}

extension NutritionPlanError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .apiError:
            return "Failed to communicate with DeepSeek API"
        case .parsingError(let detail):
            return "Failed to parse AI response: \(detail)"
        case .invalidResponse(let detail):
            return "Invalid AI response format: \(detail)"
        case .invalidMacronutrients(let detail):
            return "Invalid macronutrients: \(detail)"
        case .invalidMealSuggestions(let detail):
            return "Invalid meal suggestions: \(detail)"
        case .emptyResponse:
            return "Received empty response from AI"
        }
    }
} 