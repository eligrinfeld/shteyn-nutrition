import Foundation

struct Meal: Codable, Identifiable {
    let id: UUID
    let name: String
    let suggestions: [String]
    
    // Optional detailed nutrition info (for when we have it)
    var calories: Int?
    var proteins: Double?
    var carbohydrates: Double?
    var fats: Double?
    var ingredients: [String]?
    var instructions: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name = "meal"
        case suggestions
        case calories
        case proteins
        case carbohydrates
        case fats
        case ingredients
        case instructions
    }
    
    init(id: UUID = UUID(), 
         name: String, 
         suggestions: [String],
         calories: Int? = nil,
         proteins: Double? = nil,
         carbohydrates: Double? = nil,
         fats: Double? = nil,
         ingredients: [String]? = nil,
         instructions: String? = nil) {
        self.id = id
        self.name = name
        self.suggestions = suggestions
        self.calories = calories
        self.proteins = proteins
        self.carbohydrates = carbohydrates
        self.fats = fats
        self.ingredients = ingredients
        self.instructions = instructions
    }
}

extension Meal {
    // Helper for meal type identification
    var type: MealType {
        switch name.lowercased() {
        case "breakfast": return .breakfast
        case "lunch": return .lunch
        case "dinner": return .dinner
        case "snacks": return .snacks
        default: return .other
        }
    }
    
    enum MealType: String, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snacks = "Snacks"
        case other = "Other"
    }
} 