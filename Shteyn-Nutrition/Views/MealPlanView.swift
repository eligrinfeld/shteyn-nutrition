import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var aiManager: NutritionAIManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let plan = aiManager.currentPlan {
                    // Daily calories and macros
                    DailyStatsCard(plan: plan)
                    
                    // Meal suggestions
                    ForEach(plan.mealSuggestions) { meal in
                        MealSuggestionCard(meal: meal)
                    }
                    
                    // Recommendations
                    RecommendationsCard(recommendations: plan.recommendations)
                } else {
                    ContentUnavailableView(
                        "No Meals Generated",
                        systemImage: "fork.knife",
                        description: Text("Your personalized meal plan will appear here")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Meal Plan")
    }
}

struct DailyStatsCard: View {
    let plan: NutritionPlan
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Daily Target")
                .font(.headline)
            
            Text("\(plan.dailyCalories) calories")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                MacronutrientLabel(
                    value: Double(plan.macronutrients["protein"] ?? 0),
                    unit: "g",
                    name: "Protein"
                )
                Spacer()
                MacronutrientLabel(
                    value: Double(plan.macronutrients["carbs"] ?? 0),
                    unit: "g",
                    name: "Carbs"
                )
                Spacer()
                MacronutrientLabel(
                    value: Double(plan.macronutrients["fats"] ?? 0),
                    unit: "g",
                    name: "Fat"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct MealSuggestionCard: View {
    let meal: MealSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meal.meal)
                .font(.headline)
            
            ForEach(meal.suggestions, id: \.self) { suggestion in
                Text("• \(suggestion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct RecommendationsCard: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            ForEach(recommendations, id: \.self) { recommendation in
                Text("• \(recommendation)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct MacronutrientLabel: View {
    let value: Double
    let unit: String
    let name: String
    
    var body: some View {
        VStack(alignment: .center) {
            Text("\(Int(value))\(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 
