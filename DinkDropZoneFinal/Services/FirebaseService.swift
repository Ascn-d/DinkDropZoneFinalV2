import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreLocation
import UIKit

@Observable
final class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    // Shared Firestore reference
    private let db = Firestore.firestore()

    /// Convenience helper that executes a Firestore call and maps the SDK error into our
    /// own `FirebaseError` domain so that calling code can present a friendly message.
    private func perform<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw mapFirestoreError(error)
        }
    }

    enum FirebaseError: LocalizedError {
        case invalidUser
        case decoding
        case missingFirestore
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidUser: return "Unable to locate current Firebase user"
            case .decoding:     return "Failed to decode document"
            case .missingFirestore: return "Cloud Firestore is not enabled for this Firebase project. Please provision a database first."
            case .unknown:      return "Unknown Firebase error"
            }
        }
    }

    // MARK: - AUTHENTICATION
    @discardableResult
    func signIn(email: String, password: String) async throws -> User {
        let authData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error { continuation.resume(throwing: error) }
                else if let result = result { continuation.resume(returning: result) }
                else { continuation.resume(throwing: FirebaseError.unknown) }
            }
        }

        // Fetch the corresponding user profile (or create if missing)
        let userDoc: DocumentSnapshot
        do {
            userDoc = try await db.collection("users").document(authData.user.uid).getDocument()
        } catch {
            throw mapFirestoreError(error)
        }
        if let data = userDoc.data() {
            return try decodeUser(from: data, id: userDoc.documentID)
        } else {
            // Create a bare-bones profile based on auth info
            let newUser = User(email: email, password: "", displayName: authData.user.displayName ?? "Player")
            try await createUser(newUser, uid: authData.user.uid)
            return newUser
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let authData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error { continuation.resume(throwing: error) }
                else if let result = result { continuation.resume(returning: result) }
                else { continuation.resume(throwing: FirebaseError.unknown) }
            }
        }

        // Set Firebase display name for convenience
        let changeReq = authData.user.createProfileChangeRequest()
        changeReq.displayName = displayName
        try await changeReq.commitChanges()

        let newUser = User(email: email, password: "", displayName: displayName)
        try await createUser(newUser, uid: authData.user.uid)
        return newUser
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - USER MANAGEMENT
    func createUser(_ user: User) async throws { try await createUser(user, uid: Auth.auth().currentUser?.uid) }

    // Real-time user listener. Caller should hold the returned handle and call remove() when done.
    struct ListenerHandle { let remove: () -> Void }

    /// Observe the `users/{uid}` document and receive live `User` updates.
    /// Returns a handle whose `remove()` should be called to stop listening.
    func observeUser(id: String, onChange: @escaping (Result<User, Error>) -> Void) -> ListenerHandle {
        let listener = db.collection("users").document(id).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(self.mapFirestoreError(error)))
            } else if let snap = snapshot, let data = snap.data() {
                do {
                    let user = try self.decodeUser(from: data, id: id)
                    onChange(.success(user))
                } catch {
                    onChange(.failure(error))
                }
            }
        }
        return ListenerHandle { listener.remove() }
    }

    private func createUser(_ user: User, uid: String?) async throws {
        guard let uid = uid else { throw FirebaseError.invalidUser }
        try await perform {
            try await db.collection("users").document(uid).setData(encodeUser(user))
        }
    }

    func updateUser(_ user: User) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw FirebaseError.invalidUser }
        try await perform {
            try await db.collection("users").document(uid).updateData(encodeUser(user))
        }
    }

    func getUser(id: String) async throws -> User {
        let snapshot: DocumentSnapshot = try await perform {
            try await db.collection("users").document(id).getDocument()
        }
        guard let data = snapshot.data() else { throw FirebaseError.invalidUser }
        return try decodeUser(from: data, id: id)
    }

    // MARK: - IMAGE UPLOAD
    
    /// Uploads a profile image to Firebase Storage and returns the download URL
    func uploadProfileImage(_ image: UIImage, for userId: String) async throws -> String {
        print("FirebaseService: Starting profile image upload for user \(userId)")
        
        // Try different compression levels if needed
        var imageData: Data?
        var compressionQuality: CGFloat = 0.7
        
        // First try with standard compression
        imageData = image.jpegData(compressionQuality: compressionQuality)
        
        // If image is too large, try higher compression
        if let data = imageData, data.count > 5_000_000 { // 5MB
            compressionQuality = 0.5
            imageData = image.jpegData(compressionQuality: compressionQuality)
            print("FirebaseService: Using higher compression due to large image size")
        }
        
        guard let finalImageData = imageData else {
            print("FirebaseService: Failed to convert image to JPEG data")
            throw FirebaseError.unknown
        }
        
        print("FirebaseService: Image data size: \(finalImageData.count) bytes, compression: \(compressionQuality)")
        
        // Verify user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            print("FirebaseService: No authenticated user found")
            throw FirebaseError.invalidUser
        }
        
        print("FirebaseService: Authenticated user: \(currentUser.uid)")
        
        let storage = Storage.storage()
        let imageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        // Add cache control for better performance
        metadata.cacheControl = "public, max-age=3600"
        // Add custom metadata for debugging
        metadata.customMetadata = [
            "uploadedBy": currentUser.uid,
            "uploadTime": String(Date().timeIntervalSince1970)
        ]
        
        do {
            print("FirebaseService: Uploading image to Firebase Storage...")
            print("FirebaseService: Storage reference path: \(imageRef.fullPath)")
            print("FirebaseService: Storage bucket: \(imageRef.bucket)")
            
            // Use the completion-based upload and convert to async
            return try await withCheckedThrowingContinuation { continuation in
                let uploadTask = imageRef.putData(finalImageData, metadata: metadata) { metadata, error in
                    if let error = error {
                        print("FirebaseService: Upload failed: \(error)")
                        print("FirebaseService: Error details: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let metadata = metadata else {
                        print("FirebaseService: Upload completed but no metadata returned")
                        continuation.resume(throwing: FirebaseError.unknown)
                        return
                    }
                    
                    print("FirebaseService: Upload completed successfully")
                    print("FirebaseService: Uploaded to path: \(metadata.path ?? "unknown")")
                    print("FirebaseService: File size: \(metadata.size) bytes")
                    
                    // Get download URL immediately after successful upload
                    imageRef.downloadURL { url, error in
                        if let error = error {
                            print("FirebaseService: Failed to get download URL: \(error)")
                            print("FirebaseService: Download URL error details: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        } else if let url = url {
                            print("FirebaseService: Download URL obtained: \(url.absoluteString)")
                            continuation.resume(returning: url.absoluteString)
                        } else {
                            print("FirebaseService: No download URL returned")
                            continuation.resume(throwing: FirebaseError.unknown)
                        }
                    }
                }
                
                // Monitor upload progress
                uploadTask.observe(.progress) { snapshot in
                    if let progress = snapshot.progress {
                        let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount) * 100
                        print("FirebaseService: Upload progress: \(String(format: "%.1f", percentComplete))%")
                    }
                }
                
                // Monitor for errors during upload
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error {
                        print("FirebaseService: Upload task failed: \(error)")
                        
                        // Enhanced error logging for debugging
                        if let storageError = error as? StorageError {
                            print("FirebaseService: Upload failed: \(storageError)")
                            switch storageError {
                            case .objectNotFound:
                                print("FirebaseService: Error details: Object \(imageRef.fullPath) does not exist.")
                                print("💡 SOLUTION NEEDED: Firebase Storage is not enabled or bucket doesn't exist")
                                print("   → Go to Firebase Console → Storage → Get Started")
                            case .unauthorized:
                                print("FirebaseService: Error details: Unauthorized access. Check Firebase Storage rules.")
                                print("💡 SOLUTION NEEDED: Storage security rules are blocking the upload")
                                print("   → Go to Firebase Console → Storage → Rules")
                            case .quotaExceeded:
                                print("FirebaseService: Error details: Storage quota exceeded.")
                                print("💡 SOLUTION NEEDED: Storage quota exceeded")
                                print("   → Check Firebase billing and upgrade plan if needed")
                            default:
                                print("FirebaseService: Error details: \(storageError.localizedDescription)")
                            }
                            print("FirebaseService: Error type: StorageError")
                        } else {
                            print("FirebaseService: Error type: \(type(of: error))")
                            print("FirebaseService: Error description: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } catch {
            print("FirebaseService: Upload failed with error: \(error)")
            print("FirebaseService: Error type: \(type(of: error))")
            throw error
        }
    }
    
    /// Deletes a profile image from Firebase Storage
    func deleteProfileImage(for userId: String) async throws {
        let storage = Storage.storage()
        let imageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        try await imageRef.delete()
    }
    
    /// Updates user profile with new image URL
    func updateUserProfileImage(_ user: User, imageURL: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw FirebaseError.invalidUser }
        
        let updatedUser = user // User is a reference type, so we can modify its properties
        updatedUser.profileImageURL = imageURL
        
        try await perform {
            try await db.collection("users").document(uid).updateData([
                "profileImageURL": imageURL
            ])
        }
    }
    
    /// Complete workflow for updating user profile image
    /// This method handles: upload image -> update user document -> return updated user
    func updateProfileImageComplete(_ user: User, newImage: UIImage) async throws -> User {
        guard let uid = Auth.auth().currentUser?.uid else { 
            print("FirebaseService: No authenticated user found")
            throw FirebaseError.invalidUser 
        }
        
        print("FirebaseService: Starting complete profile image update for user ID: \(uid)")
        print("FirebaseService: User model ID: \(user.id)")
        
        // Delete old profile image if it exists
        if let oldImageURL = user.profileImageURL, !oldImageURL.isEmpty {
            print("FirebaseService: Deleting old profile image: \(oldImageURL)")
            try? await deleteProfileImage(for: uid)
        } else {
            print("FirebaseService: No existing profile image to delete")
        }
        
        // Upload new image
        print("FirebaseService: Uploading new profile image...")
        let newImageURL = try await uploadProfileImage(newImage, for: uid)
        
        // Update user document with new image URL
        print("FirebaseService: Updating user document with new image URL...")
        try await perform {
            try await db.collection("users").document(uid).updateData([
                "profileImageURL": newImageURL
            ])
        }
        print("FirebaseService: User document updated successfully")
        
        // Return updated user
        let updatedUser = user // User is a reference type, so we can modify its properties
        updatedUser.profileImageURL = newImageURL
        print("FirebaseService: Returning updated user with profile image URL: \(newImageURL)")
        return updatedUser
    }

    // MARK: - LEAGUE MANAGEMENT (placeholders, still to be implemented remotely)
    func createLeague(_ league: PickleLeague) async throws {
        // TODO: Implement once backend schema finalised
    }

    func updateLeague(_ league: PickleLeague) async throws {}
    func getLeague(id: String) async throws -> PickleLeague { throw FirebaseError.unknown }
    func getLeagues() async throws -> [PickleLeague] { [] }
    func joinLeague(_ league: PickleLeague, user: User) async throws {}
    func leaveLeague(_ league: PickleLeague, user: User) async throws {}
    func startLeague(_ league: PickleLeague) async throws {}

    // MARK: - MATCH MANAGEMENT (placeholders)
    func createMatch(_ match: LeagueMatch) async throws {}
    func updateMatch(_ match: LeagueMatch) async throws {}
    func getMatches(for league: PickleLeague) async throws -> [LeagueMatch] { [] }

    // MARK: - MATCH MANAGEMENT
    
    /// Creates a new match in Firestore
    func createMatch(_ match: GameMatch, players: [User]) async throws -> String {
        let matchId = UUID().uuidString
        
        let matchData: [String: Any] = [
            "id": matchId,
            "players": players.map { ["id": $0.id.uuidString, "displayName": $0.displayName, "elo": $0.elo] },
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "type": "singles", // Default type since GameMatch doesn't have type
            "location": "", // Default location since GameMatch doesn't have location  
            "scheduledFor": Date() // Default time since GameMatch doesn't have scheduledTime
        ]
        
        try await perform {
            try await db.collection("matches").document(matchId).setData(matchData)
        }
        
        return matchId
    }
    
    /// Updates match with result and statistics
    func completeMatch(matchId: String, result: MatchResult, players: [User]) async throws {
        let batch = db.batch()
        
        // Update match document
        let matchRef = db.collection("matches").document(matchId)
        let matchUpdate: [String: Any] = [
            "status": "completed",
            "completedAt": FieldValue.serverTimestamp(),
            "result": [
                "winner": "", // MatchResult doesn't have winnerId
                "score": "11-0", // MatchResult doesn't have score
                "pointsScored": result.pointsScored,
                "pointsConceded": result.pointsConceded,
                "eloChange": result.eloChange,
                "duration": 0 // MatchResult doesn't have duration
            ]
        ]
        batch.updateData(matchUpdate, forDocument: matchRef)
        
        // Update player statistics
        for player in players {
            let playerRef = db.collection("users").document(player.id.uuidString)
            let playerUpdate: [String: Any] = [
                "totalMatches": player.totalMatches,
                "wins": player.wins,
                "losses": player.losses,
                "winStreak": player.winStreak,
                "longestWinStreak": player.longestWinStreak,
                "totalPointsScored": player.totalPointsScored,
                "totalPointsConceded": player.totalPointsConceded,
                "elo": player.elo,
                "xp": player.xp,
                "lastActive": FieldValue.serverTimestamp()
            ]
            batch.updateData(playerUpdate, forDocument: playerRef)
        }
        
        // Create match history entry
        let historyId = UUID().uuidString
        let historyRef = db.collection("match_history").document(historyId)
        let historyData: [String: Any] = [
            "matchId": matchId,
            "playerId": players.first?.id.uuidString ?? "",
            "opponentId": players.last?.id.uuidString ?? "",
            "result": result.isWin ? "win" : "loss",
            "score": "11-0", // MatchResult doesn't have score
            "eloChange": result.eloChange,
            "date": FieldValue.serverTimestamp()
        ]
        batch.setData(historyData, forDocument: historyRef)
        
        try await batch.commit()
    }
    
    /// Gets recent matches for a user
    func getRecentMatches(for userId: String, limit: Int = 10) async throws -> [GameMatch] {
        let snapshot = try await perform {
            try await db.collection("match_history")
                .whereField("playerId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()
        }
        
        var matches: [GameMatch] = []
        for doc in snapshot.documents {
            if let match = try? decodeGameMatch(from: doc.data(), id: doc.documentID) {
                matches.append(match)
            }
        }
        return matches
    }
    
    // MARK: - ACHIEVEMENT MANAGEMENT
    
    /// Saves user achievements to Firestore
    func saveAchievements(_ achievements: [Trophy], for userId: String) async throws {
        let achievementData = achievements.map { trophy -> [String: Any] in
            var data: [String: Any] = [
                "id": trophy.id.uuidString,
                "title": trophy.title,
                "category": trophy.category.rawValue,
                "tier": trophy.tier.rawValue,
                "isUnlocked": trophy.isUnlocked,
                "progress": trophy.progress
            ]
            
            if let unlockedAt = trophy.unlockedAt {
                data["unlockedAt"] = Timestamp(date: unlockedAt)
            }
            
            return data
        }
        
        try await perform {
            try await db.collection("users").document(userId).updateData([
                "achievements": achievementData,
                "lastUpdated": FieldValue.serverTimestamp()
            ])
        }
    }
    
    /// Loads user achievements from Firestore
    func loadAchievements(for userId: String) async throws -> [Trophy] {
        let snapshot = try await perform {
            try await db.collection("users").document(userId).getDocument()
        }
        
        guard let data = snapshot.data(),
              let achievementsData = data["achievements"] as? [[String: Any]] else {
            return AchievementDefinitions.allAchievements // Return default achievements
        }
        
        var achievements: [Trophy] = []
        for achievementDict in achievementsData {
            if let achievement = try? decodeTrophy(from: achievementDict) {
                achievements.append(achievement)
            }
        }
        
        return achievements.isEmpty ? AchievementDefinitions.allAchievements : achievements
    }
    
    // MARK: - STATISTICS MANAGEMENT
    
    /// Saves detailed user statistics
    func saveUserStatistics(_ stats: DetailedUserStats, for userId: String) async throws {
        let statsData: [String: Any] = [
            "totalMatches": stats.totalMatches,
            "wins": stats.wins,
            "losses": stats.losses,
            "winRate": stats.winRate,
            "elo": stats.elo,
            "winStreak": stats.winStreak,
            "longestWinStreak": stats.longestWinStreak,
            "averagePointsScored": stats.averagePointsScored,
            "averagePointsConceded": stats.averagePointsConceded,
            "pointsDifferential": stats.pointsDifferential,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        try await perform {
            try await db.collection("user_statistics").document(userId).setData(statsData, merge: true)
        }
    }
    
    /// Loads detailed user statistics
    func loadUserStatistics(for userId: String) async throws -> DetailedUserStats? {
        let snapshot = try await perform {
            try await db.collection("user_statistics").document(userId).getDocument()
        }
        
        guard let data = snapshot.data() else { return nil }
        return try decodeUserStatistics(from: data)
    }
    
    // MARK: - SOCIAL FEATURES
    
    /// Sends a friend request
    func sendFriendRequest(from senderId: String, to recipientId: String) async throws {
        let requestId = UUID().uuidString
        let requestData: [String: Any] = [
            "id": requestId,
            "senderId": senderId,
            "recipientId": recipientId,
            "status": "pending",
            "sentAt": FieldValue.serverTimestamp()
        ]
        
        try await perform {
            try await db.collection("friend_requests").document(requestId).setData(requestData)
        }
        
        // Add to recipient's notifications
        try await addNotification(
            userId: recipientId,
            type: "friend_request",
            title: "New Friend Request",
            message: "Someone wants to be your friend!",
            data: ["requestId": requestId, "senderId": senderId]
        )
    }
    
    /// Responds to a friend request
    func respondToFriendRequest(requestId: String, accept: Bool) async throws {
        let requestRef = db.collection("friend_requests").document(requestId)
        let requestSnapshot = try await requestRef.getDocument()
        
        guard let requestData = requestSnapshot.data(),
              let senderId = requestData["senderId"] as? String,
              let recipientId = requestData["recipientId"] as? String else {
            throw FirebaseError.decoding
        }
        
        let batch = db.batch()
        
        // Update request status
        batch.updateData(["status": accept ? "accepted" : "declined"], forDocument: requestRef)
        
        if accept {
            // Add to both users' friends lists
            let friendshipId = UUID().uuidString
            let friendshipData: [String: Any] = [
                "user1": senderId,
                "user2": recipientId,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            let friendshipRef = db.collection("friendships").document(friendshipId)
            batch.setData(friendshipData, forDocument: friendshipRef)
        }
        
        try await batch.commit()
    }
    
    /// Gets user's friends
    func getFriends(for userId: String) async throws -> [User] {
        let snapshot1 = try await perform {
            try await db.collection("friendships")
                .whereField("user1", isEqualTo: userId)
                .getDocuments()
        }
        
        let snapshot2 = try await perform {
            try await db.collection("friendships")
                .whereField("user2", isEqualTo: userId)
                .getDocuments()
        }
        
        var friendIds: Set<String> = []
        
        for doc in snapshot1.documents {
            if let user2 = doc.data()["user2"] as? String {
                friendIds.insert(user2)
            }
        }
        
        for doc in snapshot2.documents {
            if let user1 = doc.data()["user1"] as? String {
                friendIds.insert(user1)
            }
        }
        
        var friends: [User] = []
        for friendId in friendIds {
            if let friend = try? await getUser(id: friendId) {
                friends.append(friend)
            }
        }
        
        return friends
    }
    
    // MARK: - NOTIFICATIONS
    
    /// Adds a notification for a user
    func addNotification(userId: String, type: String, title: String, message: String, data: [String: Any] = [:]) async throws {
        let notificationId = UUID().uuidString
        let notificationData: [String: Any] = [
            "id": notificationId,
            "userId": userId,
            "type": type,
            "title": title,
            "message": message,
            "data": data,
            "isRead": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await perform {
            try await db.collection("notifications").document(notificationId).setData(notificationData)
        }
    }
    
    /// Gets unread notifications for a user
    func getUnreadNotifications(for userId: String) async throws -> [AppNotification] {
        let snapshot = try await perform {
            try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .getDocuments()
        }
        
        var notifications: [AppNotification] = []
        for doc in snapshot.documents {
            if let notification = try? decodeAppNotification(from: doc.data(), id: doc.documentID) {
                notifications.append(notification)
            }
        }
        
        return notifications
    }
    
    /// Marks notification as read
    func markNotificationAsRead(notificationId: String) async throws {
        try await perform {
            try await db.collection("notifications").document(notificationId).updateData([
                "isRead": true,
                "readAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    // MARK: - LEADERBOARD
    
    /// Gets global leaderboard
    func getGlobalLeaderboard(limit: Int = 50) async throws -> [User] {
        let snapshot = try await perform {
            try await db.collection("users")
                .order(by: "elo", descending: true)
                .limit(to: limit)
                .getDocuments()
        }
        
        var users: [User] = []
        for doc in snapshot.documents {
            if let user = try? decodeUser(from: doc.data(), id: doc.documentID) {
                users.append(user)
            }
        }
        
        return users
    }
    
    /// Gets local leaderboard (within radius)
    func getLocalLeaderboard(center: CLLocationCoordinate2D, radiusKm: Double, limit: Int = 20) async throws -> [User] {
        let nearbyPlayers = try await fetchNearbyPlayers(center: center, radiusKm: radiusKm)
        return Array(nearbyPlayers.sorted { $0.elo > $1.elo }.prefix(limit))
    }

    // MARK: - Helper Encoding/Decoding
    private func encodeUser(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "email": user.email,
            "displayName": user.displayName,
            "elo": user.elo,
            "xp": user.xp,
            "winStreak": user.winStreak,
            "totalMatches": user.totalMatches,
            "wins": user.wins,
            "losses": user.losses,
            "lastActive": Timestamp(date: user.lastActive)
        ]
        
        // Add profile image URL if it exists
        if let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
            dict["profileImageURL"] = profileImageURL
        }
        
        // Use latest values from user instance or location cache
        if let latVal = user.lat ?? userLocationCache?.latitude,
           let lonVal = user.lon ?? userLocationCache?.longitude {
            dict["lat"] = latVal
            dict["lon"] = lonVal
        }
        return dict
    }

    private func decodeUser(from dict: [String: Any], id: String) throws -> User {
        guard let email = dict["email"] as? String else { throw FirebaseError.decoding }
        let displayName = dict["displayName"] as? String ?? "Player"
        let elo = dict["elo"] as? Int ?? 1000
        let xp = dict["xp"] as? Int ?? 0
        let winStreak = dict["winStreak"] as? Int ?? 0
        let totalMatches = dict["totalMatches"] as? Int ?? 0
        let wins = dict["wins"] as? Int ?? 0
        let losses = dict["losses"] as? Int ?? 0
        let profileImageURL = dict["profileImageURL"] as? String

        let lat = dict["lat"] as? Double
        let lon = dict["lon"] as? Double

        let user = User(
            id: UUID(uuidString: id) ?? UUID(),
            email: email,
            password: "", // Firebase handles auth
            displayName: displayName,
            profileImageURL: profileImageURL,
            elo: elo,
            xp: xp,
            totalMatches: totalMatches,
            wins: wins,
            losses: losses,
            winStreak: winStreak,
            totalPointsConceded: losses, // placeholder use losses (should be points conceded)
            lat: lat,
            lon: lon
        )
        return user
    }

    // Cache last location to include in encode
    private var userLocationCache: CLLocationCoordinate2D? = nil

    // MARK: – GEO helpers
    func updateLocation(lat: Double, lon: Double) async throws {
        userLocationCache = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        guard let uid = Auth.auth().currentUser?.uid else { throw FirebaseError.invalidUser }
        try await perform {
            try await db.collection("users").document(uid).updateData([
                "lat": lat,
                "lon": lon,
                "lastActive": FieldValue.serverTimestamp()
            ])
        }
    }

    func fetchNearbyPlayers(center: CLLocationCoordinate2D, radiusKm: Double) async throws -> [User] {
        // Bounding-box approximation because Firestore lacks true geo queries
        let earthRadiusKm = 6371.0
        let deltaLat = (radiusKm / earthRadiusKm) * 180 / Double.pi
        let deltaLon = (radiusKm / (earthRadiusKm * cos(center.latitude * Double.pi / 180))) * 180 / Double.pi

        let minLat = center.latitude - deltaLat
        let maxLat = center.latitude + deltaLat

        // Step 1: query by latitude range
        let snap = try await perform {
            try await db.collection("users")
                .whereField("lat", isGreaterThan: minLat)
                .whereField("lat", isLessThan: maxLat)
                .getDocuments()
        }

        let minLon = center.longitude - deltaLon
        let maxLon = center.longitude + deltaLon

        var results: [User] = []
        for doc in snap.documents {
            guard let _ = doc.get("lat") as? Double,
                  let lon = doc.get("lon") as? Double,
                  lon >= minLon, lon <= maxLon else { continue }
            let user = try decodeUser(from: doc.data(), id: doc.documentID)
            results.append(user)
        }
        return results
    }

    // MARK: - Helper to translate Firestore errors into typed FirebaseError
    private func mapFirestoreError(_ error: Error) -> Error {
        let nsErr = error as NSError
        // Firestore returns gRPC status code 5 (notFound) when the database hasn't been created yet.
        if nsErr.domain == FirestoreErrorDomain,
           nsErr.code == FirestoreErrorCode.notFound.rawValue,
           (nsErr.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? "").contains("database (default) does not exist") {
            return FirebaseError.missingFirestore
        }
        return error
    }
    
    // MARK: - Additional Helper Methods
    
    private func decodeGameMatch(from dict: [String: Any], id: String) throws -> GameMatch {
        // Convert Firebase match data to GameMatch format
        let opponentName = dict["opponentName"] as? String ?? "Unknown Opponent"
        let result = dict["result"] as? String ?? "win"
        let score = dict["score"] as? String ?? "11-0"
        let eloChange = dict["eloChange"] as? Int ?? 0
        let date = (dict["date"] as? Timestamp)?.dateValue() ?? Date()
        
        return GameMatch(
            opponentName: opponentName,
            result: result,
            score: score,
            eloChange: "\(eloChange)", // Convert Int to String
            date: date
        )
    }
    
    private func decodeTrophy(from dict: [String: Any]) throws -> Trophy {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = dict["title"] as? String,
              let categoryString = dict["category"] as? String,
              let tierString = dict["tier"] as? String else {
            throw FirebaseError.decoding
        }
        
        let category = AchievementCategory(rawValue: categoryString) ?? .gameplay
        let tier = AchievementTier(rawValue: tierString) ?? .bronze
        let isUnlocked = dict["isUnlocked"] as? Bool ?? false
        let progress = dict["progress"] as? [String: Int] ?? [:]
        let unlockedAt = (dict["unlockedAt"] as? Timestamp)?.dateValue()
        
        var trophy = Trophy(
            id: id,
            title: title,
            description: "", // Would need to match with definitions
            category: category,
            tier: tier,
            icon: "trophy.fill",
            conditions: []
        )
        
        trophy.isUnlocked = isUnlocked
        trophy.progress = progress
        trophy.unlockedAt = unlockedAt
        
        return trophy
    }
    
    private func encodeStats<T: Codable>(_ stats: T) -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(stats)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any] ?? [:]
        } catch {
            return [:]
        }
    }
    
    private func decodeUserStatistics(from dict: [String: Any]) throws -> DetailedUserStats {
        let totalMatches = dict["totalMatches"] as? Int ?? 0
        let wins = dict["wins"] as? Int ?? 0
        let losses = dict["losses"] as? Int ?? 0
        let winRate = dict["winRate"] as? Double ?? 0.0
        let elo = dict["elo"] as? Int ?? 1000
        let winStreak = dict["winStreak"] as? Int ?? 0
        let longestWinStreak = dict["longestWinStreak"] as? Int ?? 0
        let averagePointsScored = dict["averagePointsScored"] as? Double ?? 0.0
        let averagePointsConceded = dict["averagePointsConceded"] as? Double ?? 0.0
        let pointsDifferential = dict["pointsDifferential"] as? Int ?? 0
        
        return DetailedUserStats(
            totalMatches: totalMatches,
            wins: wins,
            losses: losses,
            winRate: winRate,
            elo: elo,
            winStreak: winStreak,
            longestWinStreak: longestWinStreak,
            averagePointsScored: averagePointsScored,
            averagePointsConceded: averagePointsConceded,
            pointsDifferential: pointsDifferential
        )
    }
    
    private func decodeAppNotification(from dict: [String: Any], id: String) throws -> AppNotification {
        guard let type = dict["type"] as? String,
              let title = dict["title"] as? String,
              let message = dict["message"] as? String else {
            throw FirebaseError.decoding
        }
        
        let notificationType: AppNotification.NotificationType
        switch type {
        case "friend_request": notificationType = .achievement // Using available type
        case "achievement": notificationType = .achievement
        case "match": notificationType = .achievement // Using available type
        default: notificationType = .achievement
        }
        
        return AppNotification(
            type: notificationType,
            title: title,
            message: message,
            data: dict["data"] as? [String: Any] ?? [:]
        )
    }
} 