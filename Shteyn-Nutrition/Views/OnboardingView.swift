import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        TabView {
            WelcomePage()
                .tag(0)
            
            UserInfoPage(user: $viewModel.user)
                .tag(1)
            
            GoalsPage(user: $viewModel.user, isPresented: $isPresented)
                .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onDisappear {
            Task {
                try? await viewModel.saveUser()
            }
        }
    }
}

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("Welcome to Shteyn Nutrition")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your AI-powered nutrition assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

private struct UserInfoPage: View {
    @Binding var user: User
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tell us about yourself")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                TextField("Name", text: $user.name)
                
                Picker("Gender", selection: $user.gender) {
                    ForEach(User.Gender.allCases, id: \.self) { gender in
                        Text(gender.rawValue.capitalized)
                    }
                }
                
                Stepper("Age: \(user.age)", value: $user.age, in: 18...100)
                
                VStack(alignment: .leading) {
                    Text("Weight (lbs)")
                    HStack {
                        Slider(value: $user.weightInPounds, in: 88...440)
                        Text("\(Int(user.weightInPounds))")
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Height")
                    HStack {
                        Picker("Feet", selection: $user.heightFeet) {
                            ForEach(4...7, id: \.self) { foot in
                                Text("\(foot) ft").tag(foot)
                            }
                        }
                        
                        Picker("Inches", selection: $user.heightInches) {
                            ForEach(0...11, id: \.self) { inch in
                                Text("\(inch) in").tag(inch)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

private struct GoalsPage: View {
    @Binding var user: User
    @Binding var isPresented: Bool
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Your Goals")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Picker("Activity Level", selection: $user.activityLevel) {
                    ForEach(User.ActivityLevel.allCases, id: \.self) { level in
                        Text(level.rawValue)
                    }
                }
                
                Picker("Nutrition Goal", selection: $user.nutritionGoal) {
                    ForEach(User.NutritionGoal.allCases, id: \.self) { goal in
                        Text(goal.rawValue)
                    }
                }
            }
            
            Button(action: {
                Task {
                    do {
                        // Test connection before proceeding
                        let isConnected = try await SupabaseService.shared.testConnection()
                        if isConnected {
                            print("Successfully connected to Supabase!")
                            isPresented = false
                        } else {
                            errorMessage = "Could not connect to database"
                            showingError = true
                        }
                    } catch {
                        errorMessage = "Connection error: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
} 