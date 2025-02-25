import Foundation

struct User: Codable, Identifiable {
    var id: UUID
    var name: String
    var age: Int
    var weight: Double
    var height: Double
    var gender: Gender
    var activityLevel: ActivityLevel
    var nutritionGoal: NutritionGoal
    var preferredUnits: UnitSystem
    
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
    
    // Computed properties with safe defaults
    var heightFeet: Int {
        get {
            if preferredUnits == .imperial {
                return Int(height / 30.48) // Convert cm to feet
            }
            return 5 // Default value
        }
        set {
            if preferredUnits == .imperial {
                let inches = Double(heightInches)
                height = Double(newValue) * 30.48 + inches * 2.54 // Convert to cm
            }
        }
    }
    
    var heightInches: Int {
        get {
            if preferredUnits == .imperial {
                let totalInches = height / 2.54 // Convert cm to inches
                return Int(totalInches.truncatingRemainder(dividingBy: 12))
            }
            return 7 // Default value
        }
        set {
            if preferredUnits == .imperial {
                let feet = Double(heightFeet)
                height = feet * 30.48 + Double(newValue) * 2.54 // Convert to cm
            }
        }
    }
    
    var weightInPounds: Double {
        get {
            if preferredUnits == .imperial {
                return weight * 2.20462 // Convert kg to lbs
            }
            return 154 // Default value
        }
        set {
            if preferredUnits == .imperial {
                weight = newValue / 2.20462 // Convert lbs to kg
            }
        }
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