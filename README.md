# Yürük - Running Tracker

Production-grade, modular, test-driven Flutter running tracker application.

## 🎯 Project Goals

- **Offline-first**: No backend, no cloud, local-only storage
- **Highly modular**: Clean architecture with strict separation of concerns
- **Test-driven**: Strong focus on unit tests and testability
- **Change isolation**: Swappable components (GPS, Map, Audio, Storage)

## 🏗️ Architecture

```
lib/
├── domain/              # Pure business logic (no Flutter)
│   ├── entities/        # Core models (TrackPoint, RunSession)
│   ├── repositories/    # Abstract interfaces
│   └── usecases/        # Business logic operations
├── application/         # Application orchestration
│   ├── controllers/     # State management
│   └── providers/       # Dependency injection
├── infrastructure/      # External dependencies
│   ├── gps/            # Location tracking
│   ├── storage/        # Data persistence
│   ├── audio/          # Text-to-speech
│   └── background/     # Background execution
├── presentation/        # UI layer
│   ├── screens/        # App screens
│   └── widgets/        # Reusable UI components
└── core/               # Shared utilities
    └── di/             # Dependency injection setup
```

## 📦 Development Phases

### ✅ Phase 1 - Core Run Session (COMPLETED)
- [x] Project structure & layered architecture
- [x] Domain entities (RunSession, TrackPoint)
- [x] Run lifecycle (start/stop)
- [x] Mock GPS implementation
- [x] Unit tests (15 tests passing)
- [x] Basic UI with live stats

**Deliverables:**
- Running Flutter app
- All tests passing
- GPS filtering logic (accuracy + speed validation)
- Distance calculation (Haversine formula)
- Pace calculation

### 🔜 Phase 2 - Real GPS
- Real GPS implementation (geolocator)
- Accuracy filtering (configurable threshold: 25m)
- Speed sanity check (max 50 km/h)
- Outlier detection (max jump 100m)
- Background location tracking

### 🔜 Phase 3 - Map Integration
- OpenStreetMap with flutter_map
- Live position marker
- Route polyline drawing
- Auto-center with manual pan disable
- Recenter button

### 🔜 Phase 4 - Interval Engine
- Distance-based intervals (e.g., 400m)
- Time-based intervals (e.g., 2 minutes)
- Target pace support
- Rest intervals (time or distance-based)
- Automatic transitions
- Event-driven architecture

### 🔜 Phase 5 - Interval + GPS Connection
- GPS → Interval engine wiring
- Real-time interval transitions
- Domain events

### 🔜 Phase 6 - Audio Guidance
- Turkish TTS implementation
- Interval transition announcements
- Background audio support

### 🔜 Phase 7 - Run Control UI
- Strava-like flow
- Session summary screen
- UI polish

### 🔜 Phase 8 - Optional Extensions
- Pause/Resume
- Heart rate optional input
- Zone notes
- Export functionality

## 🧪 Testing

Run all unit tests:
```bash
flutter test
```

Current test coverage:
- TrackPoint entity tests
- RunSession entity tests
- UpdateRunSession use case tests
- GPS accuracy & speed filtering
- Distance calculation
- Pace calculation

## 🚀 Running the App

```bash
flutter run
```

## 📱 Requirements

- Flutter 3.32.7+
- Dart 3.8.1+
- Android SDK (for Android development)
- Xcode (for iOS development)

## 🛠️ Tech Stack

- **State Management**: Riverpod
- **Dependency Injection**: GetIt
- **Value Equality**: Equatable
- **UUID Generation**: uuid
- **Storage** (planned): SQLite
- **Map** (planned): flutter_map (OpenStreetMap)
- **GPS** (planned): geolocator
- **TTS** (planned): flutter_tts
- **Background** (planned): flutter_foreground_task

## 📐 Design Principles

1. **Single Responsibility**: One class = one responsibility
2. **Dependency Injection**: All dependencies injected
3. **Interface Segregation**: Abstract all external dependencies
4. **Testability First**: If it can't be unit tested, the design is wrong
5. **Event-Driven**: Not state spaghetti
6. **No God Objects**: Small, composable units

## 🔍 GPS Filtering Strategy

1. **Accuracy threshold**: 25m (configurable)
2. **Speed sanity check**: Max 50 km/h
3. **Distance outlier**: Max 100m jump between consecutive points
4. **Bearing consistency**: Detect erratic movements

## 📄 License

Private project - All rights reserved

## 👤 Author

Alperen Üretmen
