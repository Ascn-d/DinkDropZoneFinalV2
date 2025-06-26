#!/bin/bash

# DinkDropZone Firebase Setup Script
# This script sets up Firestore collections, indexes, and security rules

echo "🔥 Setting up Firebase Firestore for DinkDropZone..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Login to Firebase (if not already logged in)
echo "🔐 Checking Firebase authentication..."
firebase login --no-localhost

# Initialize Firebase project (if not already done)
echo "📁 Initializing Firebase project..."
firebase init firestore --project dinkdropzone-app

# Create Firestore security rules
echo "🛡️ Creating Firestore security rules..."
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other users for leaderboards
    }
    
    // Matches collection - players can read/write matches they're part of
    match /matches/{matchId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid in resource.data.players || 
         request.auth.uid in get(/databases/$(database)/documents/matches/$(matchId)).data.players);
      allow create: if request.auth != null;
    }
    
    // Match history - users can read their own match history
    match /match_history/{historyId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.playerId || 
         request.auth.uid == resource.data.opponentId);
      allow create: if request.auth != null;
    }
    
    // User statistics - users can read/write their own stats
    match /user_statistics/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Friend requests - users can read requests sent to them or by them
    match /friend_requests/{requestId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.recipientId);
      allow create: if request.auth != null && request.auth.uid == request.resource.data.senderId;
      allow update: if request.auth != null && request.auth.uid == resource.data.recipientId;
    }
    
    // Friendships - users can read friendships they're part of
    match /friendships/{friendshipId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.user1 || 
         request.auth.uid == resource.data.user2);
      allow create: if request.auth != null;
    }
    
    // Notifications - users can read their own notifications
    match /notifications/{notificationId} {
      allow read, update: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Leagues - public read, members can write
    match /leagues/{leagueId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.uid == resource.data.createdBy || 
         request.auth.uid in resource.data.members);
    }
    
    // Courts - public read
    match /courts/{courtId} {
      allow read: if request.auth != null;
    }
    
    // Matchmaking queue - users can read/write their own entries
    match /matchmaking_queue/{queueId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null && request.auth.uid == resource.data.userId;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Match proposals - participants can read/write
    match /match_proposals/{proposalId} {
      allow read: if request.auth != null && request.auth.uid in resource.data.playerIds;
      allow create: if request.auth != null;
      allow update: if request.auth != null && request.auth.uid in resource.data.playerIds;
    }
    
    // Alpha testing sessions - users can write their own data, admins can read all
    match /alpha_testing_sessions/{sessionId} {
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null && request.auth.uid == resource.data.userId;
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Alpha testing metrics - same as sessions
    match /alpha_testing_metrics/{metricId} {
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null && request.auth.uid == resource.data.userId;
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
EOF

# Create Firestore indexes
echo "📊 Creating Firestore indexes..."
cat > firestore.indexes.json << 'EOF'
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "elo",
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
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isRead",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "friend_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "recipientId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "matches",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "matchmaking_queue",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "joinTime",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "matchmaking_queue",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "matchType",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "joinTime",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "match_proposals",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "playerIds",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "alpha_testing_metrics",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "timestamp",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF

# Deploy Firestore rules and indexes
echo "🚀 Deploying Firestore rules and indexes..."
firebase deploy --only firestore:rules,firestore:indexes

# Create sample data structure documentation
echo "📋 Creating data structure documentation..."
cat > FIRESTORE_STRUCTURE.md << 'EOF'
# DinkDropZone Firestore Database Structure

## Collections

### `/users/{userId}`
User profile and statistics data.
```
{
  email: string,
  displayName: string,
  profileImageURL?: string,
  elo: number,
  xp: number,
  level: number,
  totalMatches: number,
  wins: number,
  losses: number,
  winStreak: number,
  longestWinStreak: number,
  totalPointsScored: number,
  totalPointsConceded: number,
  lat?: number,
  lon?: number,
  lastActive: timestamp,
  achievements?: array,
  createdAt: timestamp
}
```

### `/matches/{matchId}`
Match data and status.
```
{
  id: string,
  players: array,
  status: string, // 'pending', 'active', 'completed'
  type: string, // 'singles', 'doubles'
  location?: string,
  scheduledFor: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp,
  result?: {
    winner: string,
    score: string,
    pointsScored: number,
    pointsConceded: number,
    eloChange: number,
    duration: number
  }
}
```

### `/match_history/{historyId}`
Individual match history entries.
```
{
  matchId: string,
  playerId: string,
  opponentId: string,
  result: string, // 'win', 'loss'
  score: string,
  eloChange: number,
  date: timestamp
}
```

### `/user_statistics/{userId}`
Detailed user statistics.
```
{
  daily: object,
  weekly: object,
  monthly: object,
  lifetime: object,
  lastUpdated: timestamp
}
```

### `/friend_requests/{requestId}`
Friend request data.
```
{
  id: string,
  senderId: string,
  recipientId: string,
  status: string, // 'pending', 'accepted', 'declined'
  sentAt: timestamp
}
```

### `/friendships/{friendshipId}`
Friendship relationships.
```
{
  user1: string,
  user2: string,
  createdAt: timestamp
}
```

### `/notifications/{notificationId}`
User notifications.
```
{
  id: string,
  userId: string,
  type: string,
  title: string,
  message: string,
  data: object,
  isRead: boolean,
  createdAt: timestamp,
  readAt?: timestamp
}
```

## Security Rules

- Users can read/write their own data
- Users can read other users' public data (for leaderboards)
- Match participants can read/write match data
- Friend requests follow sender/recipient permissions
- Notifications are private to each user

## Indexes

- Users by ELO (for leaderboards)
- Users by location (for nearby players)
- Match history by player and date
- Notifications by user, read status, and date
- Friend requests by recipient and status
EOF

echo "✅ Firebase Firestore setup completed!"
echo "📋 Check FIRESTORE_STRUCTURE.md for database structure details"
echo "🔥 Your Firebase project is ready for DinkDropZone!"

# Optional: Open Firebase console
read -p "🌐 Open Firebase console? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    firebase open
fi 