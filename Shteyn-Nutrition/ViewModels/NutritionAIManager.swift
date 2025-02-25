import Foundation

@MainActor
class NutritionAIManager: ObservableObject {
    @Published var isLoading = false
    @Published var currentPlan: NutritionPlan?
    @Published var error: String?
    
    func generateNutritionPlan(for user: User) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Generate plan using DeepSeek AI
            let plan = try await DeepSeekService.shared.generateNutritionPlan(for: user)
            
            // Save plan to Supabase
            try await SupabaseService.shared.saveNutritionPlan(plan)
            
            // Update UI
            currentPlan = plan
            
            // Get AI recommendations
            let recommendations = try await DeepSeekService.shared.getAIRecommendations(
                user: user,
                currentPlan: plan
            )
            
            // Update plan with recommendations
            var updatedPlan = plan
            updatedPlan.aiRecommendations = recommendations
            currentPlan = updatedPlan
            
            try await SupabaseService.shared.saveNutritionPlan(updatedPlan)
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func calculateBasalMetabolicRate(for user: User) -> Int {
        // Basic BMR calculation using Harris-Benedict equation
        let bmr: Double
        
        switch user.gender {
        case .male:
            bmr = 88.362 + (13.397 * user.weight) + (4.799 * user.height) - (5.677 * Double(user.age))
        case .female:
            bmr = 447.593 + (9.247 * user.weight) + (3.098 * user.height) - (4.330 * Double(user.age))
        case .other:
            // Use average of male and female calculations
            bmr = (88.362 + (13.397 * user.weight) + (4.799 * user.height) - (5.677 * Double(user.age)) +
                   447.593 + (9.247 * user.weight) + (3.098 * user.height) - (4.330 * Double(user.age))) / 2
        }
        
        return Int(bmr)
    }
} 