import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var isLoading = true
    @Published var error: Error?
    
    init() {
        // Initialize with proper default values
        self.user = User(
            id: UUID(),
            name: "",
            age: 30,
            weight: 70.0, // 70 kg
            height: 170.0, // 170 cm
            gender: .male,
            activityLevel: .moderatelyActive,
            nutritionGoal: .maintenance,
            preferredUnits: .imperial
        )
    }
    
    func loadUser() async {
        isLoading = true
        do {
            if let savedUser = try await SupabaseService.shared.getCurrentUser() {
                self.user = savedUser
            }
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }
} 