# Yürük — GPS Koşu Takip Uygulaması

Offline-first, modüler mimarili, çoklu GPS algoritma karşılaştırma destekli Flutter koşu uygulaması.

---

## Amaç

Uygulamanın temel araştırma hedefi: **farklı GPS filtreleme algoritmalarını gerçek koşu verisinde karşılaştırmak**. Hangi algoritmanın en doğru, en pürüzsüz ve Strava'ya en yakın izi çizdiğini bulmak.

---

## Özellikler

### Canlı Koşu
- Gerçek zamanlı GPS takibi
- 5 farklı algoritma aynı anda çalışır, haritada 5 renkli çizgi
- Her algoritma için anlık mesafe ve nokta istatistiği
- OpenStreetMap üzerinde rota görselleştirme
- Otomatik harita merkezleme + manuel recenter
- Süre, hız, pace gösterimi

### GPS Algoritma Karşılaştırması (Live + Lab)
| Algoritma | Renk | Açıklama |
|-----------|------|----------|
| Ham | Gri | Filtre yok, saf GPS verisi |
| Mevcut | Mavi | Kalman + standart eşikler |
| Güçlü Kalman | Yeşil | Agresif Kalman (düşük Q ve R) |
| Toleranslı | Turuncu | Gevşek eşikler, daha fazla nokta kabul |
| Katı | Kırmızı | Yüksek doğruluk eşiği, az nokta |

**Lab sekmesi:** GPX dosyası yükle → 5 algoritmayı karşılaştır → HTML rapor üret

### GPX Import / Export
- Strava, Garmin, Apple Watch gibi uygulamalardan GPX al
- Lab'e yükleyip algoritmalarla karşılaştır
- Kendi koşularını GPX olarak dışa aktar
- WhatsApp, Mail vb. uygulamalarla paylaş

### Interval Antrenman
- Mesafe bazlı interval (400m, 800m, 1km)
- Süre bazlı interval (2 dk, 5 dk)
- Hedef pace desteği
- Dinlenme aralıkları
- Özel antrenman planı oluşturma ve kaydetme

### Sesli Yönlendirme (Türkçe TTS)
- Koşu başlangıç/bitiş anonsları
- Interval geçişlerinde anlık geri bildirim
- %50 noktasında pace karşılaştırması
- Arka planda çalışma desteği

---

## Mimari

```
lib/
├── domain/                    # Saf iş mantığı (Flutter bağımlılığı yok)
│   ├── entities/              # RunSession, TrackPoint, IntervalStep, WorkoutPlan
│   ├── repositories/          # Soyut arayüzler
│   ├── usecases/              # İş operasyonları
│   └── services/              # Alan servisleri
├── application/
│   ├── controllers/           # RunSessionController, ComparisonSessionController
│   └── providers/             # Riverpod provider'ları
├── infrastructure/
│   ├── gps/                   # GeolocatorLocationRepository (ham GPS)
│   ├── import/                # GpxImporter
│   ├── export/                # GpxExporter
│   ├── storage/               # SQLite repository'leri
│   ├── tts/                   # Flutter TTS servisi
│   └── background/            # Foreground servis
├── presentation/
│   ├── screens/               # RunScreen, HistoryScreen, WorkoutsScreen, ComparisonScreen
│   ├── widgets/               # RunMapWidget, AlgorithmLegendWidget, ComparisonMapWidget, ConfigEditSheet
│   ├── map/                   # OsmMapTiles
│   └── utils/                 # RunShare
└── core/
    ├── di/                    # GetIt dependency injection
    ├── filters/               # GpsFilterPipeline, LiveAlgorithmComparator, KalmanFilter
    └── config/                # GpsFilterParams, GpsFilterConfig
```

### Temel Prensipler
- **Tek Sorumluluk**: Her sınıf tek işi yapar
- **Bağımlılık Enjeksiyonu**: GetIt ile tüm bağımlılıklar dışarıdan verilir
- **Soyutlama**: Tüm dış bağımlılıklar (GPS, DB, TTS) arayüz arkasında
- **Değiştirilebilirlik**: GPS kaynağı, harita, depolama kolayca değiştirilebilir

---

## GPS Filtreleme Katmanları

### `GeolocatorLocationRepository`
Ham GPS verisini emit eder — filtre uygulamaz. Tüm filtreleme `GpsFilterPipeline` içinde yapılır.

### `GpsFilterPipeline`
Her algoritma için bağımsız bir instance. Her gelen nokta için:

1. **Doğruluk eşiği** — Belirtilen metre üzerindeki noktalar reddedilir
2. **Maksimum hız** — GPS jitter kaynaklı anlık hız sıçramalarını eler
3. **Örtük hız** — İki nokta arası hesaplanan hız limiti
4. **Durağan nokta tespiti** — Düşük hız + düşük doğruluk → reddedilir
5. **Minimum mesafe** — Çok yakın noktalar birleştirilir
6. **Kalman filtresi** — Koordinat pürüzsüzleştirme (opsiyonel)

### `LiveAlgorithmComparator`
`RunSessionController` içinde kullanılır. Ham GPS noktalarını alır, tüm pipeline'lara dağıtır, sonuçları toplar.

---

## Tech Stack

| Kategori | Paket |
|----------|-------|
| State Management | flutter_riverpod |
| Dependency Injection | get_it |
| GPS | geolocator |
| Harita | flutter_map (OpenStreetMap) |
| Depolama | sqflite |
| TTS | flutter_tts |
| Arka Plan Servis | flutter_foreground_task |
| GPX Parsing | xml |
| Dosya Seçimi | file_picker |
| Paylaşım | share_plus |
| Crash raporu | sentry_flutter (opsiyonel, SENTRY_DSN) |
| Değer Eşitliği | equatable |

---

## Kurulum ve Çalıştırma

### Gereksinimler
- Flutter 3.41.9+
- Dart 3.11.5+
- Android SDK 24+ (Android 7.0)
- Android NDK 28.2.13676358

### Geliştirme
```bash
flutter pub get
flutter run
```

### Uygulama ikonu
Kaynak: `assets/icon.png`. Android mipmap dosyalarını yenilemek için:
```bash
dart run flutter_launcher_icons
```

### Sentry (isteğe bağlı crash raporu)
DSN repoya yazılmaz. Release build:
```bash
flutter build apk --dart-define=SENTRY_DSN=https://...@sentry.io/...
```

### Emülatörde simüle GPS
Gerçek cihazda varsayılan her zaman gerçek GPS'tir. Emülatör/test:
```bash
flutter run --dart-define=USE_SIMULATED_GPS=true
```

### Release APK (arm64)
```bash
flutter build apk --target-platform android-arm64
```

APK konumu:
```
build/app/outputs/flutter-apk/app-release.apk
```

### ADB ile Yükleme
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## CLI: GPX Karşılaştırma Aracı

Offline GPX analizi ve HTML rapor üretimi:

```bash
dart run bin/compare_gpx.dart <dosya.gpx>
```

Çıktı:
- Terminalde karşılaştırma tablosu
- `<dosya>_report.html` — Leaflet.js haritasıyla interaktif rapor

---

## GPS Filtering Strateji Detayı

### Kalman Filtre Parametreleri
| Parametre | Mevcut | Güçlü | Toleranslı | Katı |
|-----------|--------|-------|------------|------|
| Q (süreç gürültüsü) | 0.0001 | 0.00001 | 0.0001 | 0.0001 |
| R (ölçüm gürültüsü) | 0.01 | 0.001 | 0.01 | 0.01 |
| Doğruluk eşiği | 25m | 25m | 50m | 12m |
| Maks hız | 50 km/h | 50 km/h | 70 km/h | 35 km/h |

### Warm-up Fazı (İlk N nokta)
GPS soğuk başlangıçta düşük doğruluklu veri üretir. İlk N noktada filtre gevşetilir, doğruluk eşiği ve mesafe filtresi devre dışı bırakılır.

---

## Interval Antrenman Detayı

### Pace Toleransı
```
Hızlı tolerans: -hedefPace saniye (5:00 → -5 sn, 4:00 → -4 sn)
Yavaş tolerans: 0 saniye (yavaşlığa tolerans yok)
```

### %50 Geri Bildirim
| Durum | Anons |
|-------|-------|
| Hedefte | "İyi gidiyorsun!" |
| Yavaş | "3 saniye yavaşsın, hızlanabilirsin" |
| Çok hızlı | "2 saniye hızlısın, tempo düşür" |

---

## Test

```bash
flutter test
```

| Test Seti | Adet |
|-----------|------|
| Kalman Filter | 5 |
| IntervalEngine | 5 |
| IntervalSession | 10 |
| AnnouncementService | 8 |
| GPS & Filtreleme | 8 |
| RunSession | 5 |
| UpdateRunSession | 4 |
| StartRunSession | 4 |
| TrackPoint | 5 |
| GeolocatorRepository | 3 |
| **Toplam** | **57** |

---

## Proje İstatistikleri

```
Kod satırı:    ~7,000
Unit test:     57 geçti
Min Android:   7.0 (API 24)
Flutter:       3.41.9 (stable)
Dart:          3.11.5
Mimari:        Clean Architecture (4 katman)
```

---

## Lisans

Özel proje — Tüm hakları saklıdır.

## Yazar

Alperen Üretmen
