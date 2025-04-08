# A Play Manager App

A Flutter application for event organizers to manage events, concerts, and more. This app is the management counterpart to the user-facing A Play app.

## Features

- **Authentication**: User registration, login, and password reset functionality
- **Event Management**: Create, edit, and delete events
- **Profile Management**: View and edit organizer profile
- **Dark Theme**: Modern dark UI

## Technologies Used

- **Flutter**: For building the cross-platform mobile application
- **Firebase**: Authentication, Firestore (database), and Storage
- **Riverpod**: For state management
- **GoRouter**: For navigation

## Getting Started

1. Ensure you have Flutter installed on your machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Firebase Setup

The app is already configured with Firebase. The necessary `firebase_options.dart` is included.

## Organizer Verification

- When a user registers in the app, they are initially set as a regular user (`isOrganiser = false`)
- An admin must change the user's status to `isOrganiser = true` in the Firebase Firestore database to grant event management permissions

## Architecture

- **Core**: Contains app-wide utilities, constants, models, and theme
- **Features**: Contains feature-specific code (auth, events, profile)
- **Shared**: Contains shared widgets and utilities

## Contact

For any questions or support, please contact the development team.
