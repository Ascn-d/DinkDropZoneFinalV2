# 🔥 Manual Firebase Setup Guide (No CLI Required)

## Overview
This guide helps you set up Firebase for DinkDropZone using the Firebase Console instead of the CLI.

## 🚀 Step-by-Step Firebase Console Setup

### **Step 1: Access Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your DinkDropZone project
3. Ensure you're on the Blaze plan

### **Step 2: Configure Firestore Security Rules**

1. **Navigate to Firestore Database**
   - Go to "Firestore Database" in the left sidebar
   - Click on "Rules" tab

2. **Replace the rules with this code:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other users for tournaments
    }
    
    // Tournament rules - enhanced for real-time features
    match /tournaments/{tournamentId} {
      // Anyone can read tournaments (for discovery)
      allow read: if request.auth != null;
      
      // Only authenticated users can create tournaments
      allow create: if request.auth != null 
        && request.auth.uid == resource.data.organizerID;
      
      // Only organizer can update tournament settings
      allow update: if request.auth != null 
        && (request.auth.uid == resource.data.organizerID
            || isParticipantUpdate(request.auth.uid));
      
      // Only organizer can delete tournaments
      allow delete: if request.auth != null 
        && request.auth.uid == resource.data.organizerID;
      
      // Match subcollection rules
      match /matches/{matchId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null 
          && (request.auth.uid == get(/databases/$(database)/documents/tournaments/$(tournamentId)).data.organizerID
              || isMatchParticipant(request.auth.uid));
      }
    }
    
    // Match history for user statistics
    match /match_history/{historyId} {
      allow read, write: if request.auth != null 
        && (request.auth.uid == resource.data.playerId 
            || request.auth.uid == resource.data.opponentId);
    }
    
    // User notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // Helper functions
    function isParticipantUpdate(userId) {
      // Allow participants to update their own participation status
      return userId in resource.data.participantIds;
    }
    
    function isMatchParticipant(userId) {
      // Allow match participants to update match results
      return userId == resource.data.player1ID 
        || userId == resource.data.player2ID;
    }
  }
}
```

3. **Click "Publish" to deploy the rules**

### **Step 3: Configure Storage Security Rules**

1. **Navigate to Storage**
   - Go to "Storage" in the left sidebar
   - Click on "Rules" tab

2. **Replace the rules with this code:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images - users can upload their own profile images
    match /profile_images/{userId}.jpg {
      allow read: if true; // Profile images are public readable
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024 // Max 5MB
        && request.resource.contentType.matches('image/.*');
    }
    
    // Tournament images (optional for future use)
    match /tournament_images/{tournamentId}/{imageId} {
      allow read: if true; // Tournament images are public readable
      allow write: if request.auth != null
        && request.resource.size < 10 * 1024 * 1024 // Max 10MB
        && request.resource.contentType.matches('image/.*');
    }
    
    // User uploaded content (match photos, etc.)
    match /user_content/{userId}/{allPaths=**} {
      allow read: if true; // User content is public readable
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 20 * 1024 * 1024; // Max 20MB
    }
  }
}
```

3. **Click "Publish" to deploy the rules**

### **Step 4: Create Database Indexes**

1. **Navigate to Firestore Database**
   - Go to "Firestore Database" in the left sidebar
   - Click on "Indexes" tab
   - Click "Create Index"

2. **Create these indexes one by one:**

#### **Index 1: Tournament Status + Start Date**
- Collection ID: `tournaments`
- Fields:
  - `status` (Ascending)
  - `startDate` (Ascending)
- Query scopes: Collection

#### **Index 2: Tournament Skill Level + Start Date**
- Collection ID: `tournaments`
- Fields:
  - `skillLevel` (Ascending)
  - `startDate` (Ascending)
- Query scopes: Collection

#### **Index 3: Tournament Participants + Start Date**
- Collection ID: `tournaments`
- Fields:
  - `participantIds` (Array-contains)
  - `startDate` (Descending)
- Query scopes: Collection

#### **Index 4: Tournament Organizer + Start Date**
- Collection ID: `tournaments`
- Fields:
  - `organizerID` (Ascending)
  - `startDate` (Descending)
- Query scopes: Collection

#### **Index 5: Match History Player + Date**
- Collection ID: `match_history`
- Fields:
  - `playerId` (Ascending)
  - `date` (Descending)
- Query scopes: Collection

#### **Index 6: Users Location (for nearby players)**
- Collection ID: `users`
- Fields:
  - `lat` (Ascending)
  - `lon` (Ascending)
- Query scopes: Collection

### **Step 5: Verify Authentication Settings**

1. **Navigate to Authentication**
   - Go to "Authentication" in the left sidebar
   - Click on "Sign-in method" tab

2. **Enable these providers:**
   - ✅ Email/Password: Enable
   - ✅ Anonymous (optional): Enable for guest users

### **Step 6: Set Up Billing Alerts**

1. **Go to Google Cloud Console**
   - Visit [Google Cloud Console](https://console.cloud.google.com)
   - Select your Firebase project

2. **Set up billing alerts:**
   - Go to "Billing" → "Budgets & alerts"
   - Create a budget with alerts at 50%, 90%, and 100% of your desired limit

### **Step 7: Test Your Setup**

1. **Build and run your iOS app**
2. **Try creating a tournament**
3. **Test joining a tournament**
4. **Verify real-time updates work**
5. **Check Firebase Console for data**

## 🔍 **Verification Checklist**

### **Firestore Database**
- ✅ Rules deployed and active
- ✅ Indexes created and building/ready
- ✅ Security rules allow authenticated users

### **Storage**
- ✅ Rules deployed and active
- ✅ Bucket created and accessible
- ✅ Profile image uploads work

### **Authentication**
- ✅ Email/Password enabled
- ✅ Users can sign up and sign in
- ✅ Authentication required for app features

### **App Functionality**
- ✅ Tournament creation works
- ✅ Tournament registration works
- ✅ Real-time updates visible
- ✅ Match results can be submitted

## 🚨 **Common Issues & Solutions**

### **Issue: Permission Denied Errors**
**Solution:** Check that Firestore rules are deployed correctly and user is authenticated

### **Issue: Storage Upload Fails**
**Solution:** Verify Storage rules and check file size limits (max 5MB for profile images)

### **Issue: Slow Queries**
**Solution:** Ensure all required indexes are created and in "Ready" state

### **Issue: Real-time Updates Not Working**
**Solution:** Check network connection and Firebase project configuration

## 📊 **Monitoring Your Firebase Usage**

### **Firebase Console Monitoring**
1. **Firestore Usage:**
   - Go to Firestore Database → Usage tab
   - Monitor reads, writes, and deletes

2. **Storage Usage:**
   - Go to Storage → Usage tab
   - Monitor storage size and bandwidth

3. **Authentication:**
   - Go to Authentication → Usage tab
   - Monitor active users

### **Google Cloud Console Monitoring**
1. **Billing:**
   - Monitor costs and usage
   - Set up alerts for budget limits

2. **Performance:**
   - Use Cloud Monitoring for detailed metrics
   - Set up custom dashboards

## 🎉 **You're All Set!**

Your Firebase Blaze plan is now configured for:
- ✅ Real-time tournament management
- ✅ Secure user authentication
- ✅ Cloud storage for images
- ✅ Optimized database performance
- ✅ Production-ready security rules

**Test your app and enjoy your fully functional tournament system!** 