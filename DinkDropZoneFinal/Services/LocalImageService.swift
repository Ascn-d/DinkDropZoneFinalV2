import UIKit
import FirebaseFirestore
import FirebaseAuth

/// Alternative image service that stores images as Base64 in Firestore
/// Use this when Firebase Storage (Blaze plan) is not available
class LocalImageService {
    static let shared = LocalImageService()
    private let db = Firestore.firestore()
    private init() {}
    
    /// Stores profile image as Base64 string in Firestore
    func storeProfileImageLocal(_ image: UIImage, for userId: String) async throws -> String {
        guard Auth.auth().currentUser != nil else {
            throw FirebaseService.FirebaseError.invalidUser
        }
        
        print("🖼️ LocalImageService: Starting local profile image storage for user \(userId)")
        
        // Compress image significantly for Firestore storage
        let compressionQuality: CGFloat = 0.3 // Lower quality for smaller size
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw FirebaseService.FirebaseError.unknown
        }
        
        print("📊 LocalImageService: Image data size: \(imageData.count) bytes")
        
        // Firestore has a 1MB document limit, so we need to keep images small
        if imageData.count > 800_000 { // 800KB limit to be safe
            print("⚠️ LocalImageService: Image too large (\(imageData.count) bytes), compressing further...")
            
            // Try with even lower quality
            guard let smallerImageData = image.jpegData(compressionQuality: 0.15) else {
                throw FirebaseService.FirebaseError.unknown
            }
            
            if smallerImageData.count > 800_000 {
                throw FirebaseService.FirebaseError.unknown // Still too large
            }
            
            return try await storeImageData(smallerImageData, for: userId)
        }
        
        return try await storeImageData(imageData, for: userId)
    }
    
    private func storeImageData(_ imageData: Data, for userId: String) async throws -> String {
        // Convert to Base64
        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        print("💾 LocalImageService: Storing Base64 image in Firestore...")
        
        try await db.collection("users").document(userId).updateData([
            "profileImageData": base64String,
            "profileImageURL": dataURL,
            "imageUpdatedAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ LocalImageService: Profile image stored successfully")
        return dataURL
    }
    
    /// Retrieves profile image from Base64 string
    func getProfileImageLocal(for userId: String) async throws -> UIImage? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        
        guard let data = snapshot.data(),
              let base64String = data["profileImageData"] as? String else {
            return nil
        }
        
        guard let imageData = Data(base64Encoded: base64String) else {
            print("❌ LocalImageService: Failed to decode Base64 image data")
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    /// Deletes local profile image data
    func deleteProfileImageLocal(for userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "profileImageData": FieldValue.delete(),
            "profileImageURL": FieldValue.delete()
        ])
    }
}

// MARK: - Extension to FirebaseService
extension FirebaseService {
    
    /// Alternative profile image update using local storage
    func updateProfileImageLocal(_ user: User, newImage: UIImage) async throws -> User {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("FirebaseService: No authenticated user found")
            throw FirebaseService.FirebaseError.invalidUser
        }
        
        print("FirebaseService: Starting local profile image update for user ID: \(uid)")
        
        // Delete old profile image data if it exists
        if user.profileImageURL != nil {
            print("FirebaseService: Deleting old profile image data...")
            try? await LocalImageService.shared.deleteProfileImageLocal(for: uid)
        }
        
        // Store new image locally
        print("FirebaseService: Storing new profile image locally...")
        let dataURL = try await LocalImageService.shared.storeProfileImageLocal(newImage, for: uid)
        
        // Return updated user
        let updatedUser = user
        updatedUser.profileImageURL = dataURL
        print("FirebaseService: Local profile image update completed")
        return updatedUser
    }
} 