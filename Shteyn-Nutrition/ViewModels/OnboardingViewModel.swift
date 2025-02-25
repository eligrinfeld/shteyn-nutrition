import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var user = User(
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
    
    @Published var nutritionPlan: NutritionPlan?
    @Published var isGeneratingPlan = false
    @Published var error: Error?
    @Published var isLoading = false
    
    func updateUserName(_ name: String) {
        guard !name.isEmpty else { return }
        user = User(
            id: user.id,
            name: name,
            age: user.age,
            weight: user.weight,
            height: user.height,
            gender: user.gender,
            activityLevel: user.activityLevel,
            nutritionGoal: user.nutritionGoal,
            preferredUnits: user.preferredUnits
        )
    }
    
    func saveUser() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await SupabaseService.shared.saveUserProfile(user)
        
        isGeneratingPlan = true
        do {
            nutritionPlan = try await NutritionPlanService.shared.generateNutritionPlan(for: user)
            try await SupabaseService.shared.saveNutritionPlan(nutritionPlan!)
            print("Successfully generated and saved nutrition plan!")
            print("Daily Calories: \(nutritionPlan?.dailyCalories ?? 0)")
            print("Macros: \(nutritionPlan?.macronutrients ?? [:])")
            print("Meals: \(nutritionPlan?.mealSuggestions.map { $0.name } ?? [])")
        } catch {
            self.error = error
            print("Error generating nutrition plan: \(error.localizedDescription)")
        }
        isGeneratingPlan = false
    }
    
    // Test function to generate plan without saving to database
    func testGenerateNutritionPlan() async {
        isGeneratingPlan = true
        do {
            let plan = try await NutritionPlanService.shared.generateNutritionPlan(for: user)
            print("Test Plan Generated:")
            print("Daily Calories: \(plan.dailyCalories)")
            print("Macros: \(plan.macronutrients)")
            print("Meals: \(plan.mealSuggestions.map { $0.name })")
            print("AI Recommendations: \(plan.aiRecommendations)")
        } catch {
            print("Test Error: \(error.localizedDescription)")
        }
        isGeneratingPlan = false
    }
} 