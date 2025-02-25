import Foundation

struct NutritionPlan: Codable, Identifiable {
    var id: UUID
    let userId: UUID
    let dailyCalories: Int
    let macronutrients: [String: Int]
    let mealSuggestions: [MealSuggestion]
    var recommendations: [String]
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
        case recommendations
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()  // Generate new UUID for each plan
        userId = UUID()  // This should be set from the current user
        dailyCalories = try container.decode(Int.self, forKey: .dailyCalories)
        macronutrients = try container.decode([String: Int].self, forKey: .macronutrients)
        mealSuggestions = try container.decode([MealSuggestion].self, forKey: .mealSuggestions)
        recommendations = try container.decode([String].self, forKey: .recommendations)
        createdAt = Date()  // Set current date
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(dailyCalories, forKey: .dailyCalories)
        try container.encode(macronutrients, forKey: .macronutrients)
        try container.encode(mealSuggestions, forKey: .mealSuggestions)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    init(id: UUID = UUID(),
         userId: UUID,
         dailyCalories: Int,
         macronutrients: [String: Int],
         mealSuggestions: [MealSuggestion],
         recommendations: [String],
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.dailyCalories = dailyCalories
        self.macronutrients = macronutrients
        self.mealSuggestions = mealSuggestions
        self.recommendations = recommendations
        self.createdAt = createdAt
    }
}

struct MealSuggestion: Codable, Identifiable {
    var id = UUID()
    let meal: String
    let suggestions: [String]
    
    enum CodingKeys: String, CodingKey {
        case meal
        case suggestions
    }
} 