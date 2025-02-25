import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var name: String
    var age: Int
    private(set) var weight: Double // stored in kg
    private(set) var height: Double // stored in cm
    var gender: Gender
    var activityLevel: ActivityLevel
    var nutritionGoal: NutritionGoal
    var preferredUnits: UnitSystem = .imperial
    
    init(id: UUID = UUID(),
         name: String,
         age: Int,
         weight: Double,
         height: Double,
         gender: Gender,
         activityLevel: ActivityLevel,
         nutritionGoal: NutritionGoal,
         preferredUnits: UnitSystem = .imperial) {
        guard age > 0 else { fatalError("Age must be positive") }
        guard weight > 0 else { fatalError("Weight must be positive") }
        guard height > 0 else { fatalError("Height must be positive") }
        
        self.id = id
        self.name = name.isEmpty ? "New User" : name
        self.age = age
        self.weight = weight
        self.height = height
        self.gender = gender
        self.activityLevel = activityLevel
        self.nutritionGoal = nutritionGoal
        self.preferredUnits = preferredUnits
    }
    
    // Define coding keys to match database column names
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case weight
        case height
        case gender
        case activityLevel = "activity_level"
        case nutritionGoal = "nutrition_goal"
        case preferredUnits = "preferred_units"
    }
    
    // Computed properties for US units
    var weightInPounds: Double {
        get { weight * 2.20462 }
        set { weight = newValue / 2.20462 }
    }
    
    var heightFeet: Int {
        get { Int(height / 30.48) }
        set { updateHeight(feet: newValue, inches: heightInches) }
    }
    
    var heightInches: Int {
        get { Int((height.truncatingRemainder(dividingBy: 30.48)) / 2.54) }
        set { updateHeight(feet: heightFeet, inches: newValue) }
    }
    
    enum UnitSystem: String, Codable {
        case metric, imperial
    }
    
    enum Gender: String, Codable, CaseIterable {
        case male, female, other
    }
    
    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extraActive = "Extra Active"
    }
    
    enum NutritionGoal: String, Codable, CaseIterable {
        case weightLoss = "Weight Loss"
        case maintenance = "Maintenance"
        case muscleGain = "Muscle Gain"
        case healthyEating = "Healthy Eating"
    }
    
    mutating func updateHeight(feet: Int, inches: Int) {
        // Ensure inches is between 0 and 11
        let validInches = max(0, min(11, inches))
        // Convert to total centimeters
        self.height = Double(feet) * 30.48 + Double(validInches) * 2.54
    }
    
    mutating func updateWeight(pounds: Double) {
        self.weight = pounds / 2.20462
    }
} 