#!/bin/bash

echo "🔥 Setting up Firebase for DinkDropZone with Blaze Plan Features"
echo "================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed${NC}"
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

echo -e "${GREEN}✅ Firebase CLI found${NC}"

# Login to Firebase
echo -e "${BLUE}🔐 Logging into Firebase...${NC}"
firebase login

# Initialize Firebase project (if not already done)
echo -e "${BLUE}🚀 Initializing Firebase project...${NC}"
firebase init

echo -e "${YELLOW}📋 Setting up Firestore Security Rules...${NC}"

# Create enhanced Firestore rules for tournaments
cat > firestore.rules << 'EOF'
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
EOF

echo -e "${GREEN}✅ Firestore rules created${NC}"

echo -e "${YELLOW}📋 Setting up Firebase Storage Security Rules...${NC}"

# Create Firebase Storage rules
cat > storage.rules << 'EOF'
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
EOF

echo -e "${GREEN}✅ Storage rules created${NC}"

echo -e "${YELLOW}📋 Setting up Firestore Indexes...${NC}"

# Create Firestore indexes for optimal query performance
cat > firestore.indexes.json << 'EOF'
{
  "indexes": [
    {
      "collectionGroup": "tournaments",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startDate",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "tournaments",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "skillLevel",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startDate",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "tournaments",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "participantIds",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "startDate",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "tournaments",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "organizerID",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startDate",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "match_history",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "playerId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "date",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "lat",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "lon",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF

echo -e "${GREEN}✅ Firestore indexes configuration created${NC}"

echo -e "${YELLOW}🚀 Deploying Firebase configuration...${NC}"

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

echo -e "${GREEN}✅ Firebase deployment completed!${NC}"

echo -e "${BLUE}📊 Setting up Firebase Storage bucket configuration...${NC}"

# Create a script to configure Storage bucket CORS
cat > configure_storage_cors.js << 'EOF'
const { Storage } = require('@google-cloud/storage');

async function configureCORS() {
  const storage = new Storage();
  const bucketName = process.env.FIREBASE_STORAGE_BUCKET;
  
  if (!bucketName) {
    console.error('Please set FIREBASE_STORAGE_BUCKET environment variable');
    process.exit(1);
  }
  
  const corsConfiguration = [
    {
      origin: ['*'],
      method: ['GET', 'POST', 'PUT', 'DELETE'],
      responseHeader: ['Content-Type', 'Authorization'],
      maxAgeSeconds: 3600,
    },
  ];

  await storage.bucket(bucketName).setCorsConfiguration(corsConfiguration);
  console.log('✅ CORS configuration set for Storage bucket');
}

configureCORS().catch(console.error);
EOF

echo -e "${GREEN}✅ Storage CORS configuration script created${NC}"

echo -e "${YELLOW}📱 Setting up Firebase App Configuration...${NC}"

# Create Firebase configuration template
cat > firebase_config_template.swift << 'EOF'
// Firebase Configuration for DinkDropZone
// Add this to your GoogleService-Info.plist or Firebase configuration

/*
Recommended Firebase project settings for DinkDropZone:

1. Authentication:
   - Email/Password: Enabled
   - Anonymous: Enabled (for guest users)

2. Firestore Database:
   - Mode: Production
   - Location: Choose closest to your users
   - Rules: Use the generated firestore.rules

3. Storage:
   - Location: Same as Firestore
   - Rules: Use the generated storage.rules

4. Hosting (optional):
   - For tournament web dashboard

5. Cloud Functions (Blaze plan):
   - Tournament notifications
   - Match result processing
   - User statistics calculations

6. Performance Monitoring: Enabled
7. Crashlytics: Enabled
8. Analytics: Enabled
*/
EOF

echo -e "${GREEN}✅ Firebase configuration template created${NC}"

echo ""
echo -e "${GREEN}🎉 Firebase setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. ✅ Firestore rules deployed"
echo "2. ✅ Storage rules deployed" 
echo "3. ✅ Database indexes created"
echo "4. 🔄 Run your iOS app to test Firebase integration"
echo "5. 📊 Monitor usage in Firebase Console"
echo ""
echo -e "${BLUE}💡 Pro Tips for Blaze Plan:${NC}"
echo "• Set up billing alerts in Google Cloud Console"
echo "• Monitor Firestore read/write operations"
echo "• Use Firebase Performance Monitoring"
echo "• Set up Cloud Functions for advanced features"
echo ""
echo -e "${GREEN}🚀 Your tournament system is now ready for production!${NC}" 