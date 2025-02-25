import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var feet: Int = 5
    @State private var inches: Int = 7
    @State private var weightInPounds: Double = 154
    
    var body: some View {
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
                        Picker("Feet", selection: $feet) {
                            ForEach(4...7, id: \.self) { foot in
                                Text("\(foot) ft").tag(foot)
                            }
                        }
                        .frame(width: 100)
                        
                        Picker("Inches", selection: $inches) {
                            ForEach(0...11, id: \.self) { inch in
                                Text("\(inch) in").tag(inch)
                            }
                        }
                        .frame(width: 100)
                    }
                }
                .onChange(of: feet) { oldValue, newValue in
                    updateHeight()
                }
                .onChange(of: inches) { oldValue, newValue in
                    updateHeight()
                }
                
                VStack(alignment: .leading) {
                    Text("Weight (lbs)")
                    HStack {
                        Slider(value: $weightInPounds, in: 88...440) // 40-200kg in lbs
                        Text("\(Int(weightInPounds))")
                    }
                }
                .onChange(of: weightInPounds) { oldValue, newValue in
                    viewModel.user.updateWeight(pounds: newValue)
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
            
            Button(action: saveProfile) {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Save Profile")
                }
            }
            .disabled(isSaving)
        }
        .navigationTitle("Profile")
        .task {
            await viewModel.loadUser()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateHeight() {
        viewModel.user.updateHeight(feet: feet, inches: inches)
    }
    
    private func saveProfile() {
        isSaving = true
        Task {
            do {
                try await SupabaseService.shared.saveUserProfile(viewModel.user)
                isSaving = false
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isSaving = false
            }
        }
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    
    init() {
        // Default values until loaded
        self.user = User(
            id: UUID(),
            name: "",
            age: 30,
            weight: 70,
            height: 170,
            gender: .male,
            activityLevel: .moderatelyActive,
            nutritionGoal: .maintenance
        )
    }
    
    func loadUser() async {
        do {
            if let savedUser = try await SupabaseService.shared.getCurrentUser() {
                user = savedUser
            }
        } catch {
            print("Error loading user: \(error)")
        }
    }
} 