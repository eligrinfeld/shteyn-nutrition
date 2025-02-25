import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading profile...")
            } else {
                Form {
                    Section("Personal Information") {
                        TextField("Name", text: $viewModel.user.name)
                        
                        Picker("Gender", selection: $viewModel.user.gender) {
                            ForEach(User.Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue.capitalized)
                            }
                        }
                        
                        Stepper("Age: \(viewModel.user.age)", value: $viewModel.user.age, in: 18...100)
                        
                        VStack(alignment: .leading) {
                            Text("Height")
                            HStack {
                                Picker("Feet", selection: $viewModel.user.heightFeet) {
                                    ForEach(4...7, id: \.self) { foot in
                                        Text("\(foot) ft").tag(foot)
                                    }
                                }
                                
                                Picker("Inches", selection: $viewModel.user.heightInches) {
                                    ForEach(0...11, id: \.self) { inch in
                                        Text("\(inch) in").tag(inch)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Weight (lbs)")
                            HStack {
                                let weightBinding = Binding(
                                    get: { viewModel.user.weightInPounds },
                                    set: { newValue in
                                        let validValue = max(88, min(440, newValue))
                                        viewModel.user.weightInPounds = validValue
                                    }
                                )
                                
                                Slider(value: weightBinding, in: 88...440, step: 1)
                                Text("\(Int(viewModel.user.weightInPounds))")
                            }
                        }
                    }
                    
                    Section("Goals") {
                        Picker("Activity Level", selection: $viewModel.user.activityLevel) {
                            ForEach(User.ActivityLevel.allCases, id: \.self) { level in
                                Text(level.rawValue)
                            }
                        }
                        
                        Picker("Nutrition Goal", selection: $viewModel.user.nutritionGoal) {
                            ForEach(User.NutritionGoal.allCases, id: \.self) { goal in
                                Text(goal.rawValue)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: saveProfile) {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save Profile")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .task {
            await viewModel.loadUser()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveProfile() {
        isSaving = true
        Task {
            do {
                try await SupabaseService.shared.saveUserProfile(viewModel.user)
                isSaving = false
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
} 