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
} 