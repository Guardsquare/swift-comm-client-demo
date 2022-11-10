# Guardsquare Multi-User Chat Hackme Example

[![guardsquare-twitter](https://img.shields.io/twitter/follow/guardsquare?style=social)](https://twitter.com/Guardsquare)

An example of a simple chat app for iOS designed to illustrate reverse-engineering and tampering techniques in Guardsquare blogs, videos, and other education materials.

**This app is intentionally made insecure to illustrate various attack methods. Do not use it for any real communication. Do not use it as a starter for any real mobile app.**

## Getting started

### Get the app

- Download the app source code.
- Install dependencies with Swift Package Manager.
- Update the package identifier and signing information as necessary.

### Prepare your database (Optional)

Guardsquare multi-user chat hackme example comes with a sample database connection. The sample database for this app is not officially supported by Guardsquare and can be taken down at any time. If the built-in database does not work for you for any reason, here's how to create your own database from scratch.

- Create a new Firebase project.
- Download the `GoogleService-Info.plist` and replace the default file from the source control.
- Create a new Firebase Firestore database.

#### Set up users

The app has two quick login button for Alice and Bob example users. Here's how to set them up:

**Step 1** Register two users with email-based authentication:

- `alice-test@guardsquare.com` / password `123456`
- `bob-test@guardsquare.com` / password `123456`

**Step 2** Create two document in `/users` collection:

- Document ID = the ID of the user (Alice or Bob)
- `name` field equals to `Alice` and `Bob` respectively

In the same manner you can set up more users: add a user in Firebase Authentication, and for each user add a new document in `/users` collection with the document ID equal to the user ID, and with one single `name` field containing a human-readable name of that user.

#### Update database security rules

Set the database security rules to:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{documents=**} {
      allow read: if true
      allow write: if false
    }
    
    match /chats/{userIds}/{documents=**} {
      allow read, write: if request.auth != null && userIds.matches('.*' + request.auth.uid + '.*')
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

These rules would enable all users to see each other, but only read and write chat threads where they participate.

## Next steps

After your app is up and running, you are welcome to use it for any reverse-engineering practical exercises you want. 

We wish you success in learning mobile app reverse engineering.
