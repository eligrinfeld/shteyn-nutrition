import SwiftUI

@main
struct Shteyn_NutritionApp: App {
    @StateObject private var aiManager = NutritionAIManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(aiManager)
        }
    }
} 