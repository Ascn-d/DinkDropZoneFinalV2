# Firebase Storage Setup for Profile Images

## Issue
The app is experiencing a 404 "Not Found" error when trying to get download URLs for uploaded profile images. This typically happens when Firebase Storage rules are too restrictive or not properly configured.

## Firebase Storage Rules

To fix the profile image upload issue, you need to configure Firebase Storage rules in the Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`dinkdropzone`)
3. Navigate to Storage > Rules
4. Update the rules to allow authenticated users to read/write profile images:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to read/write their own profile images
    match /profile_images/{userId}.jpg {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read any profile image (for viewing other users)
    match /profile_images/{userId}.jpg {
      allow read: if request.auth != null;
    }
    
    // Fallback rule for other files
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Alternative Simple Rules (for testing)

If you want to test with more permissive rules first:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Steps to Apply Rules

1. Copy the rules above
2. Paste them in the Firebase Console > Storage > Rules
3. Click "Publish" to apply the changes
4. Test the profile image upload again

## Testing

After applying the rules, try uploading a profile image again. The console should show:
- Successful upload
- Successful download URL retrieval
- Profile image appearing in the app

## Troubleshooting

If issues persist:
1. Check Firebase Authentication is working (user is signed in)
2. Verify the Firebase project ID in `GoogleService-Info.plist`
3. Ensure Firebase Storage is enabled for your project
4. Check network connectivity
5. Look for any CORS issues in web environments 