# Yürük - Running Tracker

Production-grade, offline-first, test-driven Flutter running tracker with interval training support.

## 🎯 Project Goals

- **Offline-first**: No backend, no cloud, local-only storage
- **Highly modular**: Clean architecture with strict separation of concerns
- **Test-driven**: 50 unit tests, comprehensive coverage
- **Change isolation**: Swappable components (GPS, Map, Audio, Storage)

## 🏗️ Architecture

```
lib/
├── domain/              # Pure business logic (no Flutter)
│   ├── entities/        # Core models (TrackPoint, RunSession, IntervalStep, WorkoutPlan)
│   ├── repositories/    # Abstract interfaces
│   ├── usecases/        # Business logic operations (IntervalEngine, GPS filtering)
│   └── services/        # Domain services (AnnouncementService)
├── application/         # Application orchestration
│   ├── controllers/     # State management (RunSessionController + Interval)
│   └── providers/       # Riverpod providers
├── infrastructure/      # External dependencies
│   ├── gps/            # Geolocator + Kalman Filter
│   ├── storage/        # SQLite repositories
│   ├── tts/            # Flutter TTS
│   ├── database/       # Database helper
│   └── background/     # Foreground service
├── presentation/        # UI layer
│   ├── screens/        # Run, Workouts, History, CreateWorkout
│   └── widgets/        # RunMap, Stats, Controls
└── core/               # Shared utilities
    ├── di/             # GetIt setup
    └── filters/        # Kalman Filter
```

## ✨ Features

### 🏃 Core Running Features
- ✅ **Real-time GPS tracking** with Kalman filter smoothing
- ✅ **Live statistics**: Distance, Pace, Elapsed Time
- ✅ **OpenStreetMap integration** with route visualization
- ✅ **Smart GPS filtering**: 
  - Warm-up phase (first 10 points): Tolerant filtering
  - Post warm-up: 25m accuracy threshold
  - Speed sanity check (max 50 km/h)
  - Distance outlier detection (max 100m jump)
- ✅ **Background tracking** with foreground service
- ✅ **Session history** with SQLite persistence

### 🎯 Interval Training
- ✅ **Distance-based intervals** (e.g., 400m, 800m, 1km)
- ✅ **Time-based intervals** (e.g., 2 minutes, 5 minutes)
- ✅ **Target pace support** with real-time feedback
- ✅ **Rest intervals** with automatic transitions
- ✅ **Custom workout plans** - Create, save, and reuse
- ✅ **Smart announcements**: 
  - "400 metre hızlı başladı"
  - "400 metre tamamlandı. Tempo 4:48, hedef 5:00. 12 saniye hızlısın!"
  - "Dinlenme tamamlandı"

### 🔊 Audio Guidance
- ✅ **Turkish TTS** (flutter_tts)
- ✅ **Interval announcements** with pace feedback
- ✅ **Background audio** support

## 📦 Development Phases

### ✅ Phase 1 - Core Run Session (COMPLETED)
- ✅ Project structure & layered architecture
- ✅ Domain entities (RunSession, TrackPoint)
- ✅ Run lifecycle (start/stop)
- ✅ Mock GPS implementation
- ✅ Unit tests (8 tests)
- ✅ Basic UI with live stats

### ✅ Phase 2 - Real GPS Integration (COMPLETED)
- ✅ Geolocator implementation
- ✅ Kalman Filter for GPS smoothing (5 tests)
- ✅ Accuracy filtering (warm-up + post warm-up)
- ✅ Speed sanity check (max 50 km/h)
- ✅ Outlier detection (max 100m jump)
- ✅ Initial position fetching for immediate map display

### ✅ Phase 3 - Map Integration (COMPLETED)
- ✅ OpenStreetMap with flutter_map
- ✅ Live position marker
- ✅ Route polyline drawing
- ✅ Auto-center with manual recenter button
- ✅ Initial position display (before run starts)

### ✅ Phase 4 - Data Persistence (COMPLETED)
- ✅ SQLite integration (sqflite)
- ✅ Run session storage with JSON serialization
- ✅ History screen (view past runs)
- ✅ Delete sessions
- ✅ Repository pattern implementation

### ✅ Phase 5 - Text-to-Speech (COMPLETED)
- ✅ Turkish TTS (flutter_tts)
- ✅ Run start/stop announcements
- ✅ Announcement service with 7 unit tests

### ✅ Phase 6 - Background Tracking (COMPLETED)
- ✅ Foreground service (flutter_foreground_task)
- ✅ Android notification
- ✅ Background GPS tracking
- ✅ Screen-off support

### ✅ Phase 7 - Interval Training Engine (COMPLETED)
- ✅ Domain models (IntervalStep, WorkoutPlan, IntervalSession)
- ✅ IntervalEngine with event-driven architecture (5 tests)
- ✅ Distance & time-based intervals
- ✅ Target pace with real-time comparison
- ✅ Relative progress tracking (offset-based)
- ✅ Workout plan UI (create, list, delete)
- ✅ Plan selection on run screen
- ✅ Smart TTS announcements with pace feedback (7 tests)
- ✅ SQLite storage for workout plans
- ✅ Comprehensive test coverage (27 tests for intervals)

### 🔜 Phase 8 - Optional Extensions (Future)
- ⬜ Pause/Resume functionality
- ⬜ Heart rate monitoring
- ⬜ Zone-based training
- ⬜ Export (GPX/TCX)
- ⬜ Photo notes

## 🧪 Testing

Run all unit tests:
```bash
flutter test
```

**Test Results:** 50 PASSED ✅ | 2 SKIPPED

### Test Coverage:
```
✅ Kalman Filter (5 tests)
✅ IntervalEngine (5 tests)
✅ IntervalSession (10 tests)
✅ AnnouncementService (7 tests)
✅ GPS & Filtering (8 tests)
✅ RunSession entity (5 tests)
✅ UpdateRunSession (4 tests)
✅ StartRunSession (4 tests)
✅ TrackPoint (5 tests)
✅ GeolocatorRepository (3 tests)
```

## 🚀 Running the App

### Development Build
```bash
flutter run
```

### Production APK (Android)
```bash
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --split-per-abi
```

APK Location:
```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## 📋 Example Workout Plan

```
Name: 400m Intervallar
Description: Hız çalışması

Steps:
1. 400m Hızlı @ 5:00/km
2. 2 dakika Dinlenme
3. 400m Hızlı @ 5:00/km
4. 200m Dinlenme
```

**Expected Announcements:**
```
🔊 "400 metre hızlı başladı"
🔊 "400 metre tamamlandı. Tempo 4:55, hedef 5:00. 5 saniye hızlısın!"
🔊 "2 dakika dinlenme başladı"
🔊 "Dinlenme tamamlandı"
🔊 "400 metre hızlı başladı"
🔊 "400 metre tamamlandı. Tempo 5:10, hedef 5:00. 10 saniye yavaşsın"
🔊 "200 metre dinlenme başladı"
🔊 "Dinlenme tamamlandı"
🔊 "Tüm intervallar tamamlandı. Harika iş!"
```

## 📱 Requirements

- Flutter 3.32.7+
- Dart 3.8.1+
- Android SDK 24+ (Android 7.0)
- OpenJDK 17
- Xcode (for iOS development)

## 🛠️ Tech Stack

- **State Management**: Riverpod
- **Dependency Injection**: GetIt
- **Value Equality**: Equatable
- **UUID Generation**: uuid
- **Storage**: SQLite (sqflite)
- **Map**: flutter_map (OpenStreetMap)
- **GPS**: geolocator + Kalman Filter
- **TTS**: flutter_tts (Turkish)
- **Background**: flutter_foreground_task

## 📐 Design Principles

1. **Single Responsibility**: One class = one responsibility
2. **Dependency Injection**: All dependencies injected via GetIt
3. **Interface Segregation**: Abstract all external dependencies
4. **Testability First**: 50 unit tests, 100% domain coverage
5. **Event-Driven**: IntervalEngine uses events, not state mutations
6. **Clean Architecture**: Strict 4-layer separation

## 🔍 GPS Filtering Strategy

### Warm-up Phase (First 10 Points)
- **Accuracy threshold**: Relaxed (accepts lower accuracy points)
- **Minimum distance**: 2m between points
- **Speed check**: Bypassed during warm-up
- **Reason**: Initial GPS fix is less accurate

### Post Warm-up (After 10 Points)
- **Accuracy threshold**: 25m (strict via `TrackPoint.isAccurate`)
- **Minimum distance**: 5m between points
- **Speed sanity check**: Max 50 km/h
- **Implied speed check**: Max 100 km/h between consecutive points
- **Stationary detection**: Rejects points < 5m with speed < 0.5 m/s and accuracy > 15m

### Kalman Filter
- **Q (Process noise)**: 
  - Lat/Lng: 0.0001
  - Altitude: 0.001
  - Speed: 0.0005
- **R (Measurement noise)**: 
  - Lat/Lng: 0.01
  - Altitude: 0.05 (less accurate)
  - Speed: 0.02
- **Adaptive R**: Adjusts based on GPS accuracy
- **Applied to**: Latitude, Longitude, Altitude, Speed

## 🎯 Key Design Decisions

### 1. Relative Progress Tracking (Critical Fix!)
**Problem:** Using absolute distance caused intervals to complete at wrong points.

```dart
// ❌ WRONG:
newProgress = runSession.totalDistance;

// ✅ CORRECT:
newProgress = runSession.totalDistance - stepStartDistance;
```

**Example:**
```
Step 1: 400m → 0→400m ✅
Step 2: 200m → 400→600m ✅ (not 0→200!)
Step 3: 400m → 600→1000m ✅ (not 0→400!)
```

### 2. Separate Elapsed Timer
GPS updates are async and variable (0.5-2s). Using GPS timestamps for UI would cause jitter.

**Solution:** Separate `Timer.periodic(1s)` for smooth UI updates.

### 3. Pace Threshold
Changed from 100m → **50m** for faster user feedback.

### 4. TTS Simplicity
No mid-interval announcements to avoid distraction. Only start, completion, and workout done.

## 📄 License

Private project - All rights reserved

## 👤 Author

Alperen Üretmen

---

## 🏆 Project Stats

```
Total Lines: ~5,000
Unit Tests: 50 PASSED
Test Coverage: 100% (Domain layer)
Build Time: ~18s (release APK)
APK Size: ~25MB (arm64-v8a)
Min Android: 7.0 (API 24)
Architecture: Clean Architecture (4 layers)
```

**Last Updated:** February 2, 2026
