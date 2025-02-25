import Foundation
import SwiftUI

@MainActor
class NutritionAIManager: ObservableObject {
    @Published var currentPlan: NutritionPlan?
    @Published var isLoading = false
    @Published var error: Error?
    
    func generatePlan(for user: User) async {
        isLoading = true
        error = nil
        
        do {
            let plan = try await DeepSeekService.shared.generateNutritionPlan(for: user)
            currentPlan = plan
            
            // Save to Supabase
            try await SupabaseService.shared.saveNutritionPlan(plan)
        } catch {
            self.error = error
            print("Error generating plan: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func getRecommendations(for user: User) async {
        guard let currentPlan = currentPlan else { return }
        
        isLoading = true
        error = nil
        
        do {
            let recommendations = try await DeepSeekService.shared.getAIRecommendations(user: user, currentPlan: currentPlan)
            // Update the current plan with new recommendations
            self.currentPlan?.recommendations.append(recommendations)
        } catch {
            self.error = error
            print("Error getting recommendations: \(error.localizedDescription)")
        }
        
        isLoading = false
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