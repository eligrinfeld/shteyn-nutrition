import SwiftUI

struct ContentView: View {
    @State private var showOnboarding = true
    @EnvironmentObject var aiManager: NutritionAIManager
    
    var body: some View {
        NavigationStack {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else {
                MealPlanView()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
} 