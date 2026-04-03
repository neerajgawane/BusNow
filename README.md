# BusNow - Complete Full Stack Solution

## Architecture
- **Backend & Database:** Node.js, Express, Socket.io, PostgreSQL (Dockerized).
- **Frontend App:** Flutter application mapping both Conductor and Passenger flows.

## Setup Instructions

### 1. Start the Database and Backend API
In the root `BusNow` directory, run:
```bash
docker-compose up -d --build
```
This will automatically:
1. Initialize the PostgreSQL database with the correct `schema.sql` (and seed data).
2. Build the `busnow-api` Node.js container.
3. Start the Node.js server on `http://localhost:3000`.

### 2. Start the Flutter App
Make sure your emulator is running, or a device is plugged in.
```bash
cd busnow_app
flutter pub get
flutter run
```

### 3. Demo Flow
1. Open the app on the emulator/device, select "I'm a Conductor".
2. Login with Phone: `9876543210`, Password: `BusNow@Conductor1`.
3. Open a second device/emulator (or run as macOS/Web app for ease). Select "I'm a Passenger".
4. Login / Register as a passenger.
5. In Conductor view, tap "Overcrowded". Notice your XP increase dynamically.
6. In Passenger view, select the "Adyar Signal" stop. See **Bus 21C** arriving. The bus will be marked with a red border ("OVERCROWDED") and recommend "Wait for next bus".
7. Tap the 'Map' icon in Passenger view, and you will see the bus marker automatically trace the generated Socket GPS pings from the Conductor's background geolocator hook!

### 4. Note on Production Deployment
- Update the default `.env` files with actual production keys.
- **Google Maps:** Place your Android `google_maps_api_key` in `busnow_app/android/app/src/main/AndroidManifest.xml` and the equivalent iOS files for real maps to start rendering beneath the markers!
- **Firebase FCM:** Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in respective places to activate background FCM push notifications. Note: App gracefully falls back if not present.
