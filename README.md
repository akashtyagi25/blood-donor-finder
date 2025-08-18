# Blood Donor Finder App

A Flutter app to connect blood donors and recipients, built with Firebase for authentication and real-time data. The app streamlines the process of finding and donating blood in emergencies.

## Features

- **User Registration & Login**
  - Register as a blood donor or recipient
  - Firebase authentication
  - Donors and recipients have separate homepages

- **Profile Management**
  - View real user data (name, email, phone, blood group, location)
  - Donor and recipient profile pages
  - Donors can update their availability

- **Emergency Alerts**
  - Recipients can send emergency alerts with description, location, blood group, and phone number
  - Alerts are saved in Firestore

- **Donor Homepage**
  - Donors see only those recipient alerts whose blood group matches theirs
  - Alerts display recipient name, location, phone, and blood group
  - Real-time updates using Firestore streams

- **Navigation**
  - Bottom navigation bar for Home and Profile pages (for donors)
  - Clean navigation for all user types

- **OpenStreetMap Integration**
  - Location picker for registration and alerts using flutter_map (no Google Maps API required)

## Project Structure

- `lib/screens/` — General screens (register, login, homepage, profile, emergency alert)
- `lib/donor/` — Donor-specific homepage, profile page, and alert tile widget
- Firebase logic handled in screens using Firestore and Auth

## How It Works

1. Users register as a donor or recipient.
2. Recipients can send emergency alerts with their details.
3. Donors see only matching alerts and can contact recipients directly.
4. All user and alert data is stored and synced in Firebase Firestore.

## Tech Stack
- Flutter
- Firebase Auth & Firestore
- flutter_map (OpenStreetMap)

## Future Improvements
- Hospital integration
- Push notifications
- In-app chat
- Donation history
- User verification

---

This app helps save lives by making blood donation and requests fast, reliable, and accessible.


