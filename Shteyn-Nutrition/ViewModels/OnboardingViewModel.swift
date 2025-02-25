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
    
    @Published var isLoading = false
    @Published var error: Error?
    
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
        
        // Save user to Supabase
        try await SupabaseService.shared.saveUserProfile(user)
    }
} 