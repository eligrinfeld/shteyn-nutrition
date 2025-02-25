import Foundation

struct NutritionPlan: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let dailyCalories: Int
    let macronutrients: [String: Int]
    let mealSuggestions: [Meal]
    var aiRecommendations: String
    let createdAt: Date
    
    // Computed properties for macronutrients with nil coalescing
    var protein: Int { macronutrients["protein"] ?? 0 }
    var carbs: Int { macronutrients["carbs"] ?? 0 }
    var fats: Int { macronutrients["fats"] ?? 0 }
    
    // Total calories from macros validation
    var calculatedCalories: Int {
        (protein * 4) + (carbs * 4) + (fats * 9)
    }
    
    // Macro percentages with safe division
    var proteinPercentage: Double {
        guard dailyCalories > 0 else { return 0 }
        return Double(protein * 4) / Double(dailyCalories) * 100
    }
    
    var carbsPercentage: Double {
        guard dailyCalories > 0 else { return 0 }
        return Double(carbs * 4) / Double(dailyCalories) * 100
    }
    
    var fatsPercentage: Double {
        guard dailyCalories > 0 else { return 0 }
        return Double(fats * 9) / Double(dailyCalories) * 100
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dailyCalories = "daily_calories"
        case macronutrients
        case mealSuggestions = "meal_suggestions"
        case aiRecommendations = "recommendations"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        dailyCalories = try container.decode(Int.self, forKey: .dailyCalories)
        macronutrients = try container.decode([String: Int].self, forKey: .macronutrients)
        mealSuggestions = try container.decode([Meal].self, forKey: .mealSuggestions)
        aiRecommendations = try container.decode(String.self, forKey: .aiRecommendations)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(dailyCalories, forKey: .dailyCalories)
        try container.encode(macronutrients, forKey: .macronutrients)
        try container.encode(mealSuggestions, forKey: .mealSuggestions)
        try container.encode(aiRecommendations, forKey: .aiRecommendations)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    init(id: UUID = UUID(),
         userId: UUID,
         dailyCalories: Int,
         macronutrients: [String: Int],
         mealSuggestions: [Meal],
         aiRecommendations: String,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.dailyCalories = dailyCalories
        self.macronutrients = macronutrients
        self.mealSuggestions = mealSuggestions
        self.aiRecommendations = aiRecommendations
        self.createdAt = createdAt
    }
} 