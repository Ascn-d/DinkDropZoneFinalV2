import SwiftUI
import PhotosUI
import SwiftData

struct ProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User
    
    @State private var displayName: String
    @State private var bio: String
    @State private var location: String
    @State private var selectedSkillLevel: String
    @State private var selectedPlayStyle: String
    @State private var favoriteShot: String
    @State private var availability: [String: Bool]
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var email: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(user: User) {
        self.user = user
        _displayName = State(initialValue: user.displayName)
        _bio = State(initialValue: user.bio)
        _location = State(initialValue: user.location)
        _selectedSkillLevel = State(initialValue: user.skillLevel)
        _selectedPlayStyle = State(initialValue: user.playStyle)
        _favoriteShot = State(initialValue: user.favoriteShot)
        _availability = State(initialValue: user.availability)
        _email = State(initialValue: user.email)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Image Section
                Section {
                    HStack {
                        Spacer()
                        if let imageURL = user.profileImageURL {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Change Profile Picture", systemImage: "photo")
                    }
                }
                
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Display Name", text: $displayName)
                    TextField("Location", text: $location)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Game Info Section
                Section("Game Information") {
                    Picker("Skill Level", selection: $selectedSkillLevel) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.rawValue)
                                .tag(level.rawValue)
                        }
                    }
                    
                    Picker("Play Style", selection: $selectedPlayStyle) {
                        ForEach(PlayStyle.allCases, id: \.self) { style in
                            Text(style.rawValue)
                                .tag(style.rawValue)
                        }
                    }
                    
                    TextField("Favorite Shot", text: $favoriteShot)
                }
                
                // Availability Section
                Section("Availability") {
                    ForEach(Calendar.current.weekdaySymbols, id: \.self) { day in
                        Toggle(day, isOn: Binding(
                            get: { availability[day] ?? false },
                            set: { availability[day] = $0 }
                        ))
                    }
                }
                
                Section(header: Text("Profile Information")) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("ELO Rating")
                        Spacer()
                        Text("\(user.elo)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total Matches")
                        Spacer()
                        Text("\(user.totalMatches)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Win Rate")
                        Spacer()
                        Text(String(format: "%.1f%%", user.totalMatches > 0 ? Double(user.wins) / Double(user.totalMatches) * 100 : 0))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Current Win Streak")
                        Spacer()
                        Text("\(user.winStreak)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveChanges() {
        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
        
        // Check if email is already taken
        let currentUserId = user.id
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.email == email && user.id != currentUserId
            }
        )
        
        if (try? modelContext.fetch(descriptor).first) != nil {
            alertMessage = "This email is already in use"
            showingAlert = true
            return
        }
        
        // Update user
        user.displayName = displayName
        user.bio = bio
        user.location = location
        user.skillLevel = selectedSkillLevel
        user.playStyle = selectedPlayStyle
        user.favoriteShot = favoriteShot
        user.availability = availability
        user.email = email
        
        // TODO: Handle profile image upload
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save changes"
            showingAlert = true
        }
    }
}

#Preview {
    PreviewHelper.profileEditViewPreview()
}

@MainActor
private struct PreviewHelper {
    static func profileEditViewPreview() -> some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: User.self, configurations: config)
        
        let user = User(
            email: "test@example.com",
            password: "password123",
            elo: 1000,
            xp: 0,
            totalMatches: 10,
            wins: 7,
            losses: 3,
            winStreak: 2
        )
        
        container.mainContext.insert(user)
        
        return ProfileEditView(user: user)
            .modelContainer(container)
    }
} 