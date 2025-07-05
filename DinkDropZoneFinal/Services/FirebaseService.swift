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

    // MARK: - TOURNAMENT MANAGEMENT
    
    /// Creates a new tournament in Firestore
    func createTournament(_ tournament: Tournament) async throws -> String {
        let tournamentData = encodeTournament(tournament)
        
        try await perform {
            try await db.collection("tournaments").document(tournament.id.uuidString).setData(tournamentData)
        }
        
        print("✅ Tournament created in Firebase: \(tournament.name) (ID: \(tournament.id.uuidString))")
        return tournament.id.uuidString
    }
    
    /// Updates tournament in Firestore
    func updateTournament(_ tournament: Tournament) async throws {
        let tournamentData = encodeTournament(tournament)
        
        try await perform {
            try await db.collection("tournaments").document(tournament.id.uuidString).updateData(tournamentData)
        }
        
        print("✅ Tournament updated in Firebase: \(tournament.name)")
    }
    
    /// Gets a specific tournament
    func getTournament(id: String) async throws -> Tournament {
        let snapshot: DocumentSnapshot = try await perform {
            try await db.collection("tournaments").document(id).getDocument()
        }
        guard let data = snapshot.data() else { 
            print("❌ Tournament not found: \(id)")
            throw FirebaseError.invalidUser 
        }
        
        let tournament = try decodeTournament(from: data, id: id)
        print("✅ Tournament fetched from Firebase: \(tournament.name)")
        return tournament
    }
    
    /// Gets all tournaments with optional filtering
    func getAllTournaments(status: String? = nil, limit: Int? = nil) async throws -> [Tournament] {
        var query: Query = db.collection("tournaments")
            .order(by: "startDate", descending: false)
        
        if let status = status {
            query = query.whereField("status", isEqualTo: status)
        }
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let snapshot = try await perform {
            try await query.getDocuments()
        }
        
        var tournaments: [Tournament] = []
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                tournaments.append(tournament)
            }
        }
        
        print("✅ Fetched \(tournaments.count) tournaments from Firebase")
        return tournaments
    }
    
    /// Gets tournaments with pagination support
    func getTournaments(
        lastDocument: DocumentSnapshot? = nil,
        limit: Int = 20,
        status: String? = nil,
        skillLevel: String? = nil
    ) async throws -> (tournaments: [Tournament], lastDocument: DocumentSnapshot?) {
        var query: Query = db.collection("tournaments")
            .order(by: "startDate", descending: false)
            .limit(to: limit)
        
        if let status = status {
            query = query.whereField("status", isEqualTo: status)
        }
        
        if let skillLevel = skillLevel {
            query = query.whereField("skillLevel", isEqualTo: skillLevel)
        }
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await perform {
            try await query.getDocuments()
        }
        
        var tournaments: [Tournament] = []
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                tournaments.append(tournament)
            }
        }
        
        let lastDoc = snapshot.documents.last
        print("✅ Fetched \(tournaments.count) tournaments (paginated) from Firebase")
        return (tournaments, lastDoc)
    }
    
    /// Real-time tournament listener
    func observeTournament(id: String, onChange: @escaping (Result<Tournament, Error>) -> Void) -> ListenerHandle {
        print("🔄 Setting up real-time listener for tournament: \(id)")
        let listener = db.collection("tournaments").document(id).addSnapshotListener { snapshot, error in
            if let error {
                print("❌ Tournament listener error: \(error)")
                onChange(.failure(self.mapFirestoreError(error)))
            } else if let snap = snapshot, let data = snap.data() {
                do {
                    let tournament = try self.decodeTournament(from: data, id: id)
                    print("🔄 Tournament updated via listener: \(tournament.name)")
                    onChange(.success(tournament))
                } catch {
                    print("❌ Tournament decode error: \(error)")
                    onChange(.failure(error))
                }
            }
        }
        return ListenerHandle { listener.remove() }
    }
    
    /// Real-time listener for all tournaments
    func observeAllTournaments(onChange: @escaping (Result<[Tournament], Error>) -> Void) -> ListenerHandle {
        print("🔄 Setting up real-time listener for all tournaments")
        let listener = db.collection("tournaments")
            .order(by: "startDate", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("❌ All tournaments listener error: \(error)")
                    onChange(.failure(self.mapFirestoreError(error)))
                } else if let snap = snapshot {
                    var tournaments: [Tournament] = []
                    for doc in snap.documents {
                        if let tournament = try? self.decodeTournament(from: doc.data(), id: doc.documentID) {
                            tournaments.append(tournament)
                        }
                    }
                    print("🔄 All tournaments updated via listener: \(tournaments.count) tournaments")
                    onChange(.success(tournaments))
                }
            }
        return ListenerHandle { listener.remove() }
    }
    
    /// Gets tournaments where user is registered
    func getUserTournaments(userId: String) async throws -> [Tournament] {
        print("🔍 Fetching tournaments for user: \(userId)")
        let snapshot = try await perform {
            try await db.collection("tournaments")
                .whereField("participantIds", arrayContains: userId)
                .order(by: "startDate", descending: true) // Most recent first for user tournaments
                .getDocuments()
        }
        
        var tournaments: [Tournament] = []
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                tournaments.append(tournament)
            }
        }
        
        print("✅ Found \(tournaments.count) tournaments for user: \(userId)")
        return tournaments
    }
    
    /// Registers a user for a tournament
    func registerForTournament(tournamentId: String, participant: TournamentParticipant) async throws {
        print("📝 Registering participant: \(participant.displayName) for tournament: \(tournamentId)")
        
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let tournamentDoc: DocumentSnapshot
            do {
                tournamentDoc = try transaction.getDocument(tournamentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = tournamentDoc.data() else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var tournament = try? self.decodeTournament(from: data, id: tournamentId) else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if user is already registered
            if tournament.participants.contains(where: { $0.userID == participant.userID }) {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User already registered"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if tournament is full
            if tournament.participants.count >= tournament.maxParticipants {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament is full"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Add participant
            tournament.participants.append(participant)
            
            // Update status if needed
            if tournament.participants.count >= tournament.maxParticipants {
                tournament.status = "Registration Closed"
            }
            
            // Update tournament
            let updatedData = self.encodeTournament(tournament)
            transaction.updateData(updatedData, forDocument: tournamentRef)
            
            return nil
        }
        
        print("✅ Successfully registered participant: \(participant.displayName)")
    }
    
    /// Removes a user from a tournament
    func leaveTournament(tournamentId: String, userId: String) async throws {
        print("🚪 User leaving tournament: \(userId) from \(tournamentId)")
        
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let tournamentDoc: DocumentSnapshot
            do {
                tournamentDoc = try transaction.getDocument(tournamentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = tournamentDoc.data() else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var tournament = try? self.decodeTournament(from: data, id: tournamentId) else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Find and remove participant
            let originalCount = tournament.participants.count
            tournament.participants.removeAll { $0.userID == userId }
            
            if tournament.participants.count == originalCount {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found in tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Update status if needed
            if tournament.status == "Registration Closed" && tournament.participants.count < tournament.maxParticipants {
                tournament.status = "Registration Open"
            }
            
            // Update tournament
            let updatedData = self.encodeTournament(tournament)
            transaction.updateData(updatedData, forDocument: tournamentRef)
            
            return nil
        }
        
        print("✅ Successfully removed user from tournament")
    }
    
    /// Updates tournament match result
    func updateTournamentMatch(tournamentId: String, match: TournamentMatch) async throws {
        print("🏓 Updating match result: \(match.displayName) in tournament: \(tournamentId)")
        
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let tournamentDoc: DocumentSnapshot
            do {
                tournamentDoc = try transaction.getDocument(tournamentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = tournamentDoc.data() else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var tournament = try? self.decodeTournament(from: data, id: tournamentId) else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Find and update the match
            if let matchIndex = tournament.matches.firstIndex(where: { $0.id == match.id }) {
                tournament.matches[matchIndex] = match
                
                // Update participant records if match is completed
                if match.status == "Completed", let winnerID = match.winnerID, let loserID = match.loserID {
                    if let winnerIndex = tournament.participants.firstIndex(where: { $0.userID == winnerID }) {
                        tournament.participants[winnerIndex].wins += 1
                    }
                    if let loserIndex = tournament.participants.firstIndex(where: { $0.userID == loserID }) {
                        tournament.participants[loserIndex].losses += 1
                    }
                }
                
                // Check if tournament is complete
                let completedMatches = tournament.matches.filter { $0.status == "Completed" }
                let totalMatches = tournament.matches.count
                
                if completedMatches.count == totalMatches && totalMatches > 0 {
                    tournament.status = "Completed"
                    // Calculate final placements
                    self.calculateFinalPlacements(&tournament)
                }
                
                let updatedData = self.encodeTournament(tournament)
                transaction.updateData(updatedData, forDocument: tournamentRef)
            } else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Match not found in tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            return nil
        }
        
        print("✅ Successfully updated match result")
    }
    
    /// Batch update tournament matches
    func updateTournamentMatches(tournamentId: String, matches: [TournamentMatch]) async throws {
        print("🏓 Batch updating \(matches.count) matches in tournament: \(tournamentId)")
        
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let tournamentDoc: DocumentSnapshot
            do {
                tournamentDoc = try transaction.getDocument(tournamentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = tournamentDoc.data() else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var tournament = try? self.decodeTournament(from: data, id: tournamentId) else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Update all matches
            for updatedMatch in matches {
                if let matchIndex = tournament.matches.firstIndex(where: { $0.id == updatedMatch.id }) {
                    tournament.matches[matchIndex] = updatedMatch
                }
            }
            
            let updatedData = self.encodeTournament(tournament)
            transaction.updateData(updatedData, forDocument: tournamentRef)
            
            return nil
        }
        
        print("✅ Successfully batch updated matches")
    }
    
    /// Deletes a tournament (for organizers only)
    func deleteTournament(tournamentId: String, organizerId: String) async throws {
        print("🗑️ Deleting tournament: \(tournamentId) by organizer: \(organizerId)")
        
        // First verify the user is the organizer
        let tournament = try await getTournament(id: tournamentId)
        guard tournament.organizerID == organizerId else {
            throw FirebaseError.invalidUser
        }
        
        try await perform {
            try await db.collection("tournaments").document(tournamentId).delete()
        }
        
        print("✅ Tournament deleted successfully")
    }
    
    /// Search tournaments by name or venue
    func searchTournaments(query: String, limit: Int = 20) async throws -> [Tournament] {
        print("🔍 Searching tournaments with query: \(query)")
        
        // Firebase doesn't support full-text search, so we'll do a simple name search
        let snapshot = try await perform {
            try await db.collection("tournaments")
                .whereField("name", isGreaterThanOrEqualTo: query)
                .whereField("name", isLessThan: query + "\u{f8ff}")
                .limit(to: limit)
                .getDocuments()
        }
        
        var tournaments: [Tournament] = []
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                tournaments.append(tournament)
            }
        }
        
        print("✅ Found \(tournaments.count) tournaments matching query: \(query)")
        return tournaments
    }
    
    /// Gets tournaments by organizer
    func getTournamentsByOrganizer(organizerId: String) async throws -> [Tournament] {
        print("🔍 Fetching tournaments by organizer: \(organizerId)")
        
        let snapshot = try await perform {
            try await db.collection("tournaments")
                .whereField("organizerID", isEqualTo: organizerId)
                .order(by: "startDate", descending: true)
                .getDocuments()
        }
        
        var tournaments: [Tournament] = []
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                tournaments.append(tournament)
            }
        }
        
        print("✅ Found \(tournaments.count) tournaments by organizer: \(organizerId)")
        return tournaments
    }
    
    // MARK: - Enhanced Tournament Methods for Scalability
    
    /// Batch register multiple participants for a tournament
    func batchRegisterParticipants(tournamentId: String, participants: [TournamentParticipant]) async throws {
        print("📝 Batch registering \(participants.count) participants for tournament: \(tournamentId)")
        
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let tournamentDoc: DocumentSnapshot
            do {
                tournamentDoc = try transaction.getDocument(tournamentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = tournamentDoc.data() else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var tournament = try? self.decodeTournament(from: data, id: tournamentId) else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if tournament can accommodate all participants
            let availableSlots = tournament.maxParticipants - tournament.participants.count
            if participants.count > availableSlots {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not enough slots available. Need \(participants.count), but only \(availableSlots) available."])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check for duplicate registrations
            for participant in participants {
                if tournament.participants.contains(where: { $0.userID == participant.userID }) {
                    let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User \(participant.displayName) already registered"])
                    errorPointer?.pointee = error
                    return nil
                }
            }
            
            // Add all participants
            tournament.participants.append(contentsOf: participants)
            
            // Update status if needed
            if tournament.participants.count >= tournament.maxParticipants {
                tournament.status = "Registration Closed"
            }
            
            let updatedData = self.encodeTournament(tournament)
            transaction.updateData(updatedData, forDocument: tournamentRef)
            
            return nil
        }
        
        print("✅ Successfully batch registered \(participants.count) participants")
    }
    
    /// Get tournaments with advanced filtering and pagination
    func getFilteredTournaments(
        status: [String]? = nil,
        skillLevels: [String]? = nil,
        formats: [String]? = nil,
        location: (latitude: Double, longitude: Double, radiusKm: Double)? = nil,
        startDateRange: (from: Date, to: Date)? = nil,
        lastDocument: DocumentSnapshot? = nil,
        limit: Int = 20
    ) async throws -> (tournaments: [Tournament], lastDocument: DocumentSnapshot?) {
        
        var query: Query = db.collection("tournaments")
            .order(by: "startDate", descending: false)
            .limit(to: limit)
        
        // Apply status filter
        if let statuses = status, !statuses.isEmpty {
            query = query.whereField("status", in: statuses)
        }
        
        // Apply skill level filter
        if let skillLevels = skillLevels, !skillLevels.isEmpty {
            query = query.whereField("skillLevel", in: skillLevels)
        }
        
        // Apply format filter
        if let formats = formats, !formats.isEmpty {
            query = query.whereField("format", in: formats)
        }
        
        // Apply date range filter
        if let dateRange = startDateRange {
            query = query
                .whereField("startDate", isGreaterThanOrEqualTo: dateRange.from)
                .whereField("startDate", isLessThanOrEqualTo: dateRange.to)
        }
        
        // Apply pagination
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await perform {
            try await query.getDocuments()
        }
        
        var tournaments: [Tournament] = []
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                tournaments.append(tournament)
            }
        }
        
        // Apply location filter if specified (client-side filtering)
        if location != nil {
            tournaments = tournaments.filter { tournament in
                // For now, we'll skip location filtering since we don't have coordinates in Tournament model
                // In a real implementation, you'd add latitude/longitude fields to Tournament
                return true
            }
        }
        
        let lastDoc = snapshot.documents.last
        print("✅ Fetched \(tournaments.count) filtered tournaments")
        return (tournaments, lastDoc)
    }
    
    /// Get tournament statistics for analytics
    func getTournamentStatistics(organizerId: String? = nil) async throws -> TournamentStatistics {
        var query: Query = db.collection("tournaments")
        
        if let organizerId = organizerId {
            query = query.whereField("organizerID", isEqualTo: organizerId)
        }
        
        let snapshot = try await perform {
            try await query.getDocuments()
        }
        
        var statistics = TournamentStatistics()
        
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                statistics.totalTournaments += 1
                statistics.totalParticipants += tournament.participants.count
                
                switch tournament.status {
                case "Registration Open":
                    statistics.openTournaments += 1
                case "In Progress":
                    statistics.activeTournaments += 1
                case "Completed":
                    statistics.completedTournaments += 1
                default:
                    break
                }
                
                if tournament.participants.count >= tournament.maxParticipants {
                    statistics.fullTournaments += 1
                }
            }
        }
        
        print("✅ Tournament statistics calculated: \(statistics.totalTournaments) total tournaments")
        return statistics
    }
    
    /// Enhanced real-time tournament collection listener with filtering
    func observeFilteredTournaments(
        status: [String]? = nil,
        limit: Int = 50,
        onChange: @escaping (Result<[Tournament], Error>) -> Void
    ) -> ListenerHandle {
        print("🔄 Setting up filtered tournament listener")
        
        var query: Query = db.collection("tournaments")
            .order(by: "startDate", descending: false)
            .limit(to: limit)
        
        if let statuses = status, !statuses.isEmpty {
            query = query.whereField("status", in: statuses)
        }
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Filtered tournaments listener error: \(error)")
                onChange(.failure(self.mapFirestoreError(error)))
            } else if let snap = snapshot {
                var tournaments: [Tournament] = []
                for doc in snap.documents {
                    if let tournament = try? self.decodeTournament(from: doc.data(), id: doc.documentID) {
                        tournaments.append(tournament)
                    }
                }
                print("🔄 Filtered tournaments updated: \(tournaments.count) tournaments")
                onChange(.success(tournaments))
            }
        }
        
        return ListenerHandle { listener.remove() }
    }
    
    /// Bulk update tournament matches (for bracket progression)
    func bulkUpdateTournamentMatches(tournamentId: String, matches: [TournamentMatch], updateStatus: Bool = true) async throws {
        print("🏓 Bulk updating \(matches.count) matches in tournament: \(tournamentId)")
        
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let tournamentDoc: DocumentSnapshot
            do {
                tournamentDoc = try transaction.getDocument(tournamentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = tournamentDoc.data() else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var tournament = try? self.decodeTournament(from: data, id: tournamentId) else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Update matches
            for updatedMatch in matches {
                if let matchIndex = tournament.matches.firstIndex(where: { $0.id == updatedMatch.id }) {
                    tournament.matches[matchIndex] = updatedMatch
                    
                    // Update participant records if match is completed
                    if updatedMatch.status == "Completed", let winnerID = updatedMatch.winnerID, let loserID = updatedMatch.loserID {
                        if let winnerIndex = tournament.participants.firstIndex(where: { $0.userID == winnerID }) {
                            tournament.participants[winnerIndex].wins += 1
                        }
                        if let loserIndex = tournament.participants.firstIndex(where: { $0.userID == loserID }) {
                            tournament.participants[loserIndex].losses += 1
                        }
                    }
                }
            }
            
            // Check tournament completion if requested
            if updateStatus {
                let completedMatches = tournament.matches.filter { $0.status == "Completed" }
                let totalMatches = tournament.matches.count
                
                if completedMatches.count == totalMatches && totalMatches > 0 {
                    tournament.status = "Completed"
                    self.calculateFinalPlacements(&tournament)
                }
            }
            
            let updatedData = self.encodeTournament(tournament)
            transaction.updateData(updatedData, forDocument: tournamentRef)
            
            return nil
        }
        
        print("✅ Successfully bulk updated matches")
    }
    
    /// Start tournament with bracket generation
    func startTournamentWithBracket(tournamentId: String, matches: [TournamentMatch]) async throws {
        print("🏁 Starting tournament with bracket: \(tournamentId)")
        
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let tournamentDoc: DocumentSnapshot
            do {
                tournamentDoc = try transaction.getDocument(tournamentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = tournamentDoc.data() else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var tournament = try? self.decodeTournament(from: data, id: tournamentId) else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Validate tournament can be started
            guard tournament.status == "Registration Closed" || tournament.status == "Registration Open" else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament cannot be started from status: \(tournament.status)"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard tournament.participants.count >= 4 else {
                let error = NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Need at least 4 participants to start tournament"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Update tournament
            tournament.status = "In Progress"
            tournament.matches = matches
            
            let updatedData = self.encodeTournament(tournament)
            transaction.updateData(updatedData, forDocument: tournamentRef)
            
            return nil
        }
        
        print("✅ Tournament started successfully with \(matches.count) matches")
    }
    
    /// Get tournament leaderboard
    func getTournamentLeaderboard(limit: Int = 50) async throws -> [TournamentLeaderboardEntry] {
        print("🏆 Fetching tournament leaderboard")
        
        // Get all completed tournaments
        let snapshot = try await perform {
            try await db.collection("tournaments")
                .whereField("status", isEqualTo: "Completed")
                .order(by: "endDate", descending: true)
                .limit(to: 100)
                .getDocuments()
        }
        
        var playerStats: [String: TournamentLeaderboardEntry] = [:]
        
        for doc in snapshot.documents {
            if let tournament = try? decodeTournament(from: doc.data(), id: doc.documentID) {
                for participant in tournament.participants {
                    let userId = participant.userID
                    
                    if var entry = playerStats[userId] {
                        entry.tournamentsPlayed += 1
                        entry.totalWins += participant.wins
                        entry.totalLosses += participant.losses
                        
                        if let placement = participant.placement {
                            if placement == 1 {
                                entry.championships += 1
                            }
                            entry.totalPlacement += placement
                        }
                        
                        playerStats[userId] = entry
                    } else {
                        let placement = participant.placement ?? 999
                        let entry = TournamentLeaderboardEntry(
                            userId: userId,
                            displayName: participant.displayName,
                            tournamentsPlayed: 1,
                            championships: placement == 1 ? 1 : 0,
                            totalWins: participant.wins,
                            totalLosses: participant.losses,
                            totalPlacement: placement,
                            averageRank: Double(placement),
                            winRate: 0.0,
                            points: 0
                        )
                        playerStats[userId] = entry
                    }
                }
            }
        }
        
        // Calculate final stats and sort
        var leaderboard = playerStats.values.map { entry in
            var finalEntry = entry
            finalEntry.averageRank = Double(finalEntry.totalPlacement) / Double(finalEntry.tournamentsPlayed)
            finalEntry.winRate = finalEntry.totalWins + finalEntry.totalLosses > 0 ? 
                Double(finalEntry.totalWins) / Double(finalEntry.totalWins + finalEntry.totalLosses) : 0.0
            
            // Calculate points (championships worth more)
            finalEntry.points = finalEntry.championships * 100 + finalEntry.totalWins * 3 - Int(finalEntry.averageRank)
            
            return finalEntry
        }
        
        leaderboard.sort { $0.points > $1.points }
        
        print("✅ Generated leaderboard with \(leaderboard.count) players")
        return Array(leaderboard.prefix(limit))
    }

    // MARK: - Tournament Helper Methods
    
    /// Calculates final placements for completed tournament
    private func calculateFinalPlacements(_ tournament: inout Tournament) {
        print("🏆 Calculating final placements for tournament: \(tournament.name)")
        
        // Sort participants by wins, then by losses (ascending)
        let sortedParticipants = tournament.participants.sorted { p1, p2 in
            if p1.wins != p2.wins {
                return p1.wins > p2.wins
            }
            return p1.losses < p2.losses
        }
        
        for (index, participant) in sortedParticipants.enumerated() {
            if let participantIndex = tournament.participants.firstIndex(where: { $0.id == participant.id }) {
                tournament.participants[participantIndex].placement = index + 1
            }
        }
        
        // Log final standings
        for participant in tournament.participants.sorted(by: { ($0.placement ?? 999) < ($1.placement ?? 999) }) {
            if let placement = participant.placement {
                print("🏆 \(placement). \(participant.displayName) - \(participant.wins)W/\(participant.losses)L")
            }
        }
    }
    
    // MARK: - Tournament Encoding/Decoding Methods
    
    /// Encodes a Tournament object to Firestore data
    private func encodeTournament(_ tournament: Tournament) -> [String: Any] {
        var data: [String: Any] = [
            "name": tournament.name,
            "description": tournament.description,
            "type": tournament.type,
            "format": tournament.format,
            "skillLevel": tournament.skillLevel,
            "maxParticipants": tournament.maxParticipants,
            "startDate": tournament.startDate,
            "endDate": tournament.endDate,
            "status": tournament.status,
            "organizerID": tournament.organizerID,
            "organizerName": tournament.organizerName,
            "venueName": tournament.venueName,
            "venueAddress": tournament.venueAddress,
            "updatedAt": Date()
        ]
        
        // Encode participants
        let participantsData = tournament.participants.map { participant in
            return [
                "id": participant.id.uuidString,
                "userID": participant.userID,
                "displayName": participant.displayName,
                "elo": participant.elo,
                "status": participant.status,
                "placement": participant.placement as Any,
                "isEliminated": participant.isEliminated,
                "wins": participant.wins,
                "losses": participant.losses,
                "partnerID": participant.partnerID as Any,
                "partnerName": participant.partnerName as Any,
                "teamName": participant.teamName as Any
            ]
        }
        data["participants"] = participantsData
        
        // Encode matches
        let matchesData = tournament.matches.map { match in
            return [
                "id": match.id.uuidString,
                "round": match.round,
                "bracket": match.bracket,
                "matchNumber": match.matchNumber,
                "player1ID": match.player1ID,
                "player2ID": match.player2ID,
                "player1Name": match.player1Name,
                "player2Name": match.player2Name,
                "winnerID": match.winnerID as Any,
                "loserID": match.loserID as Any,
                "status": match.status,
                "finalScore": match.finalScore,
                "isBye": match.isBye,
                "isGrandFinalReset": match.isGrandFinalReset,
                "scheduledTime": match.scheduledTime as Any,
                "court": match.court as Any,
                "notes": match.notes
            ]
        }
        data["matches"] = matchesData
        
        return data
    }
    
    /// Decodes Firestore data to a Tournament object
    private func decodeTournament(from data: [String: Any], id: String) throws -> Tournament {
        guard let name = data["name"] as? String,
              let description = data["description"] as? String,
              let type = data["type"] as? String,
              let format = data["format"] as? String,
              let skillLevel = data["skillLevel"] as? String,
              let maxParticipants = data["maxParticipants"] as? Int,
              let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
              let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
              let status = data["status"] as? String,
              let organizerID = data["organizerID"] as? String,
              let organizerName = data["organizerName"] as? String,
              let venueName = data["venueName"] as? String,
              let venueAddress = data["venueAddress"] as? String else {
            throw FirebaseError.decoding
        }
        
        // Decode participants
        var participants: [TournamentParticipant] = []
        if let participantsData = data["participants"] as? [[String: Any]] {
            for participantData in participantsData {
                if let idString = participantData["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let userID = participantData["userID"] as? String,
                   let displayName = participantData["displayName"] as? String,
                   let elo = participantData["elo"] as? Int {
                    
                    let participant = TournamentParticipant(
                        id: id,
                        userID: userID,
                        displayName: displayName,
                        elo: elo,
                        status: participantData["status"] as? String ?? "Registered",
                        placement: participantData["placement"] as? Int,
                        isEliminated: participantData["isEliminated"] as? Bool ?? false,
                        wins: participantData["wins"] as? Int ?? 0,
                        losses: participantData["losses"] as? Int ?? 0,
                        partnerID: participantData["partnerID"] as? String,
                        partnerName: participantData["partnerName"] as? String,
                        teamName: participantData["teamName"] as? String
                    )
                    participants.append(participant)
                }
            }
        }
        
        // Decode matches
        var matches: [TournamentMatch] = []
        if let matchesData = data["matches"] as? [[String: Any]] {
            for matchData in matchesData {
                if let idString = matchData["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let round = matchData["round"] as? Int,
                   let bracket = matchData["bracket"] as? String,
                   let matchNumber = matchData["matchNumber"] as? Int,
                   let player1ID = matchData["player1ID"] as? String,
                   let player2ID = matchData["player2ID"] as? String,
                   let player1Name = matchData["player1Name"] as? String,
                   let player2Name = matchData["player2Name"] as? String,
                   let status = matchData["status"] as? String {
                    
                    let match = TournamentMatch(
                        id: id,
                        round: round,
                        bracket: bracket,
                        matchNumber: matchNumber,
                        player1ID: player1ID,
                        player2ID: player2ID,
                        player1Name: player1Name,
                        player2Name: player2Name,
                        winnerID: matchData["winnerID"] as? String,
                        loserID: matchData["loserID"] as? String,
                        status: status,
                        finalScore: matchData["finalScore"] as? String ?? "",
                        isBye: matchData["isBye"] as? Bool ?? false,
                        isGrandFinalReset: matchData["isGrandFinalReset"] as? Bool ?? false,
                        scheduledTime: (matchData["scheduledTime"] as? Timestamp)?.dateValue(),
                        court: matchData["court"] as? Int,
                        notes: matchData["notes"] as? String ?? ""
                    )
                    matches.append(match)
                }
            }
        }
        
        return Tournament(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            description: description,
            type: type,
            format: format,
            skillLevel: skillLevel,
            maxParticipants: maxParticipants,
            startDate: startDate,
            endDate: endDate,
            status: status,
            organizerID: organizerID,
            organizerName: organizerName,
            venueName: venueName,
            venueAddress: venueAddress,
            participants: participants,
            matches: matches
        )
    }
} 
