
# 🚌 BusNow

### Real-Time Bus Crowding & Arrival Monitor

> **Buildathon MVP · System Engineering Track · 24-Hour Build**

BusNow is a two-sided Flutter application that connects bus conductors and passengers on a shared real-time data layer — solving the invisible problem of overcrowded Indian city buses.

---

## 📌 Problem Statement

Public bus passengers in Indian cities have **zero visibility** into bus conditions before boarding:

* 🔴 **Overcrowding** — passengers board dangerously packed buses with no alternative info
* 🔴 **No arrival info** — commuters wait blindly at stops with no ETA
* 🔴 **Authority blindspot** — transport bodies have no live crowd distribution data

> **Key Insight:** Every bus already has a conductor — always present, responsible, and a trusted source of ground truth. No IoT. No sensors. Just a tap.

---

## ✅ Solution

Two interfaces. One app. Real-time data layer powered by Socket.io.

| Conductor App                            | Passenger App                             |
| ---------------------------------------- | ----------------------------------------- |
| Log in with assigned Bus ID + Route      | Log in and select their bus stop          |
| Tap crowd level in 2 seconds (4 options) | See list of incoming buses with ETA       |
| Phone GPS auto-tracks bus location       | See crowd level per bus (color-coded)     |
| Socket.io pushes update instantly        | Get a**Board / Wait**recommendation |

---

## 🎨 Crowd Status System

| Level          | Capacity     | Color  |
| -------------- | ------------ | ------ |
| 🟢 Empty       | < 20% full   | Green  |
| 🟡 Moderate    | 20–60% full | Amber  |
| 🟠 Full        | 60–90% full | Orange |
| 🔴 Overcrowded | > 90% full   | Red    |

---

## 🛠 Tech Stack

| Layer                | Technology                       |
| -------------------- | -------------------------------- |
| Frontend (both apps) | Flutter (Dart)                   |
| Backend              | Node.js + Express                |
| Database             | PostgreSQL                       |
| Real-time            | Socket.io                        |
| Authentication       | JWT                              |
| Maps & ETA           | Google Maps API                  |
| Deployment           | Railway (backend) + APK (mobile) |

---

## 📁 Project Structure

```
busnow/
├── backend/
│   ├── busnow_app/
│   │   ├── server.js           # Express + Socket.io entry point
│   │   ├── routes/             # API route handlers
│   │   ├── src/                # Business logic, middleware
│   │   ├── config/             # DB config, env setup
│   │   ├── schema.sql          # PostgreSQL schema
│   │   ├── seed_raj.js         # Demo data seeder
│   │   └── Dockerfile
│   └── docker-compose.yml
│
└── busnow_app/                 # Flutter app
    └── lib/
        ├── core/
        │   ├── api_client.dart
        │   └── auth_provider.dart
        ├── screens/
        │   ├── conductor/
        │   │   ├── conductor_dashboard.dart
        │   │   └── crowd_selector.dart
        │   ├── passenger/
        │   │   ├── bus_list_screen.dart
        │   │   └── stop_selector.dart
        │   ├── maps_screen.dart
        │   ├── conductor_stats_screen.dart
        │   └── login_screen.dart
        ├── services/
        │   ├── api_service.dart
        │   └── socket_service.dart
        ├── widgets/
        │   └── crowd_badge.dart
        └── utils/
            └── constants.dart
```

---

## 🗄 Database Schema

```sql
-- Core 4 tables

users        → id, name, phone, role, bus_id, route_id, password_hash, xp, rank
routes       → id, route_number, route_name, stops (JSONB)
buses        → id, bus_number, route_id, conductor_id, current_lat, current_lng, crowd_level, last_updated
crowd_logs   → id, bus_id, conductor_id, crowd_level, lat, lng, timestamp
```

---

## ⚡ Socket.io Events

| Event                   | Direction                         | Payload                                    |
| ----------------------- | --------------------------------- | ------------------------------------------ |
| `bus:crowd_update`    | Conductor → Server → Passengers | `{ bus_id, crowd_level, lat, lng }`      |
| `bus:location_update` | Conductor → Server → Passengers | `{ bus_id, lat, lng, timestamp }`        |
| `stop:subscribe`      | Passenger → Server               | `{ stop_id }`                            |
| `stop:incoming_buses` | Server → Passenger               | `[{ bus_id, eta_minutes, crowd_level }]` |

---

## 🔌 API Routes

| Method    | Endpoint                    | Description                            |
| --------- | --------------------------- | -------------------------------------- |
| `POST`  | `/api/auth/login`         | Login for both roles — returns JWT    |
| `GET`   | `/api/routes/:id/stops`   | Get all stops with coordinates         |
| `PATCH` | `/api/buses/:id/crowd`    | Conductor updates crowd level + GPS    |
| `GET`   | `/api/stops/:id/buses`    | Get incoming buses for a stop with ETA |
| `GET`   | `/api/buses/:id/location` | Get live lat/lng of a bus              |
| `GET`   | `/api/conductor/stats`    | Conductor XP, rank, badges             |

---

## 🚀 Getting Started

### Prerequisites

* Node.js v18+
* PostgreSQL 14+
* Flutter SDK 3.x
* Docker (optional)

### Backend Setup

```bash
# 1. Navigate to backend
cd backend/busnow_app

# 2. Install dependencies
npm install

# 3. Set up environment variables
cp .env.example .env
# Fill in: DATABASE_URL, JWT_SECRET, PORT, GOOGLE_MAPS_API_KEY

# 4. Run schema
psql -U postgres -d busnow -f schema.sql

# 5. Seed demo data
node seed_raj.js

# 6. Start server
node server.js
```

### With Docker

```bash
cd backend
docker-compose up --build
```

### Flutter App Setup

```bash
# 1. Navigate to Flutter app
cd busnow_app

# 2. Install dependencies
flutter pub get

# 3. Update backend URL in constants.dart
# const String baseUrl = 'https://your-railway-url.up.railway.app';

# 4. Run on device/emulator
flutter run
```

### Build APK (for demo)

```bash
flutter build apk --release
# Output: build/outputs/flutter-apk/app-release.apk
```

---

## 🌐 Deployment

### Backend → Railway

1. Push backend to GitHub
2. Connect Railway to the repo
3. Add PostgreSQL plugin in Railway dashboard
4. Set environment variables in Railway
5. Deploy — Railway gives you a public URL

### Flutter → APK

1. Update `constants.dart` with your Railway URL
2. Run `flutter build apk --release`
3. Install APK on demo phones

> ⚠️ **Demo Day Tip:** Use a personal hotspot, not venue WiFi. Both phones need internet to reach the Railway backend.

---

## 🎮 Gamification (Conductor-side)

### XP System

| Action                     | XP Reward |
| -------------------------- | --------- |
| Crowd update submitted     | +10 XP    |
| Full route shift completed | +25 XP    |
| 7-day update streak        | +50 XP    |
| Update during peak hours   | +15 XP    |

### Rank Tiers

| Rank               | XP Range        |
| ------------------ | --------------- |
| 🥉 Rookie Reporter | 0 – 500 XP     |
| 🥈 Route Veteran   | 500 – 2000 XP  |
| 🥇 Road Guardian   | 2000 – 5000 XP |
| 🏆 Transit Legend  | 5000+ XP        |

### Badges

`Route Expert` · `Peak Warrior` · `Zero Miss Week` · `Top Conductor of the Month`

---

## 🎬 Demo Script (2 Minutes)

1. Open **Conductor App** — log in as *Conductor Raj* → Bus 21C, Route: Adyar to T. Nagar
2. Show conductor dashboard — bus assignment visible, crowd not yet set
3. Tap **"Overcrowded"** — one tap, 2 seconds
4. Switch to **Passenger App** on second device — watch Bus 21C turn 🔴 in real time
5. Show ETA screen — *Bus 21C: 4 mins (Overcrowded) · Next Bus 21C: 12 mins (Empty)*
6. Point out **"Wait for next bus"** recommendation — auto-generated
7. Show **XP score jump** on conductor stats screen — gamification live
8. Show **Google Maps view** — bus marker moving along the route

---

## 📦 MVP Scope

### ✅ In MVP

* Conductor login + crowd tap UI
* Passenger stop selector + bus list
* Live crowd status (4 levels)
* GPS-based ETA calculation (Haversine formula)
* Socket.io real-time push
* Google Maps bus marker
* Basic XP + rank gamification
* JWT auth for both roles

### ❌ Out of MVP (v2+)

* Payment / ticketing integration
* Authority admin dashboard
* ML-based crowd prediction
* OTP-based phone auth
* Offline mode
* Multi-language support

---

## 👥 Team

Built in 24 hours at Buildathon · System Engineering Track

---

## 📄 License

MIT
