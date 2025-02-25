import SwiftUI

struct ContentView: View {
    @State private var showOnboarding = true
    @EnvironmentObject var aiManager: NutritionAIManager
    
    var body: some View {
        NavigationStack {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else {
                TabView {
                    MealPlanView()
                        .tabItem {
                            Label("Meal Plan", systemImage: "fork.knife")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                }
            }
        }
    }
} 