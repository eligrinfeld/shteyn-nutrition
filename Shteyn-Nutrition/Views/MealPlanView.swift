import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var aiManager: NutritionAIManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(aiManager.currentPlan?.mealSuggestions ?? [], id: \.id) { meal in
                    MealCard(meal: meal)
                }
                
                if aiManager.currentPlan?.mealSuggestions.isEmpty ?? true {
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

struct MealCard: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meal.name)
                .font(.headline)
            
            HStack {
                MacronutrientLabel(value: meal.proteins ?? 0, unit: "g", name: "Protein")
                Spacer()
                MacronutrientLabel(value: meal.carbohydrates ?? 0, unit: "g", name: "Carbs")
                Spacer()
                MacronutrientLabel(value: meal.fats ?? 0, unit: "g", name: "Fat")
            }
            
            if let ingredients = meal.ingredients, !ingredients.isEmpty {
                Text("Ingredients")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(ingredients, id: \.self) { ingredient in
                    Text("• \(ingredient)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
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
