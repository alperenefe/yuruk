import 'package:flutter/material.dart';
import '../filters/simple_kalman_filter.dart';
import '../utils/geo_math.dart';

export '../filters/simple_kalman_filter.dart';
export '../utils/geo_math.dart';

class GpsFilterParams {
  final String name;
  final Color color;
  final bool useKalman;
  final double kalmanLatLngQ;
  final double kalmanLatLngR;
  final double accuracyThreshold;
  final double maxSpeedKmh;
  final double maxImpliedSpeedKmh;
  final int warmUpCount;
  final double warmUpMinDistance;
  final double postWarmUpMinDistance;
  final double stationarySpeedThreshold;
  final double poorAccuracyThreshold;

  /// Spike Guard: Ham GPS koordinat hız eşiği (m/s). 0 = devre dışı.
  /// Kalman'dan ÖNCE uygulanır. Koşucu için 10 m/s (36 km/h) iyi bir sınır:
  /// sprint ~7 m/s geçer, GPS spike ~50+ m/s olur → yakalanır.
  /// 180° geri dönüş: hız normal (<7 m/s) → reddedilmez.
  /// Bel bandı uyumlu: GPS koordinat tabanlı, ivmeölçer kullanmaz.
  final double rawSpikeSpeedMs;

  /// IIR Adaptive: GPS Doppler hızına dayalı state machine.
  /// true ise Kalman yerine adaptif EMA filtresi kullanılır.
  /// Bel bandı uyumlu: ivmeölçer yerine GPS speed field kullanır
  /// (Doppler tabanlı, telefon yöneliminden etkilenmez).
  final bool useAdaptiveIir;

  /// STEADY_RUN durumunda EMA alpha: düşük = güçlü smoothing.
  /// output = alpha * yeni_GPS + (1-alpha) * önceki_output
  final double iirAlphaSteady;

  /// PACE_CHANGE durumunda EMA alpha: yüksek = hafif smoothing, hızlı tepki.
  final double iirAlphaPaceChange;

  /// Hız değişim eşiği (m/s): bu kadar hız değişimi PACE_CHANGE tetikler.
  /// 0.8 m/s ≈ ~3 km/h pace farkı.
  final double speedChangeThresholdMs;

  /// STOP durumunda EMA alpha. 0.0 = pozisyonu dondur (varsayılan, GPS jitter'ı önler).
  /// Küçük değer (0.05) = çok yavaş sürükle; 0.0 = tamamen dondur.
  final double iirAlphaStop;

  const GpsFilterParams({
    required this.name,
    required this.color,
    this.useKalman = true,
    this.kalmanLatLngQ = 0.0001,
    this.kalmanLatLngR = 0.01,
    this.accuracyThreshold = 25.0,
    this.maxSpeedKmh = 50.0,
    this.maxImpliedSpeedKmh = 100.0,
    this.warmUpCount = 10,
    this.warmUpMinDistance = 2.0,
    this.postWarmUpMinDistance = 5.0,
    this.stationarySpeedThreshold = 0.5,
    this.poorAccuracyThreshold = 15.0,
    this.rawSpikeSpeedMs = 0,
    this.useAdaptiveIir = false,
    this.iirAlphaSteady = 0.3,
    this.iirAlphaPaceChange = 0.7,
    this.speedChangeThresholdMs = 0.8,
    this.iirAlphaStop = 0.0,
  });

  static const GpsFilterParams raw = GpsFilterParams(
    name: 'Ham',
    color: Color(0xFF9E9E9E),
    useKalman: false,
    accuracyThreshold: 9999,
    maxSpeedKmh: 9999,
    maxImpliedSpeedKmh: 9999,
    warmUpCount: 0,
    warmUpMinDistance: 0,
    postWarmUpMinDistance: 0,
    stationarySpeedThreshold: 0,
    poorAccuracyThreshold: 9999,
  );

  static const GpsFilterParams current = GpsFilterParams(
    name: 'Mevcut',
    color: Color(0xFF2196F3),
    useKalman: true,
    kalmanLatLngQ: 0.0001,
    kalmanLatLngR: 0.01,
    accuracyThreshold: 25.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 100.0,
    warmUpCount: 10,
    warmUpMinDistance: 2.0,
    postWarmUpMinDistance: 5.0,
    stationarySpeedThreshold: 0.5,
    poorAccuracyThreshold: 15.0,
  );

  static const GpsFilterParams aggressiveKalman = GpsFilterParams(
    name: 'Güçlü Kalman',
    color: Color(0xFF4CAF50),
    useKalman: true,
    kalmanLatLngQ: 0.00001,
    kalmanLatLngR: 0.001,
    accuracyThreshold: 25.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 100.0,
    warmUpCount: 10,
    warmUpMinDistance: 2.0,
    postWarmUpMinDistance: 5.0,
    stationarySpeedThreshold: 0.5,
    poorAccuracyThreshold: 15.0,
  );

  static const GpsFilterParams lenient = GpsFilterParams(
    name: 'Toleranslı',
    color: Color(0xFFFF9800),
    useKalman: true,
    kalmanLatLngQ: 0.0001,
    kalmanLatLngR: 0.01,
    accuracyThreshold: 50.0,
    maxSpeedKmh: 70.0,
    maxImpliedSpeedKmh: 150.0,
    warmUpCount: 5,
    warmUpMinDistance: 1.0,
    postWarmUpMinDistance: 3.0,
    stationarySpeedThreshold: 0.3,
    poorAccuracyThreshold: 25.0,
  );

  static const GpsFilterParams strict = GpsFilterParams(
    name: 'Katı',
    color: Color(0xFFF44336),
    useKalman: true,
    kalmanLatLngQ: 0.0001,
    kalmanLatLngR: 0.01,
    accuracyThreshold: 12.0,
    maxSpeedKmh: 35.0,
    maxImpliedSpeedKmh: 70.0,
    warmUpCount: 15,
    warmUpMinDistance: 3.0,
    postWarmUpMinDistance: 8.0,
    stationarySpeedThreshold: 0.8,
    poorAccuracyThreshold: 10.0,
  );

  /// Strava-benzeri variant 1: Kalman yok.
  /// Strava analizi: ortalama 22.95° yön değişimi, 80 spike → ham GPS.
  /// Strava haritada güzel görünüyor çünkü 1Hz nokta yoğunluğu var, filtre değil.
  /// 0.5m + speed koşulu: sadece durma sırasındaki GPS jitter'ini keser,
  /// koşarken (speed > 0.3 m/s) tüm noktaları kabul eder.
  static const GpsFilterParams stravaRaw = GpsFilterParams(
    name: 'S1-Saf',
    color: Color(0xFFFC4C02),
    useKalman: false,
    accuracyThreshold: 20.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 150.0,
    warmUpCount: 3,
    warmUpMinDistance: 0.5,
    postWarmUpMinDistance: 0.5,
    stationarySpeedThreshold: 0.3,
    poorAccuracyThreshold: 20.0,
  );

  /// Strava-benzeri variant 2: Minimal Kalman (R=0.0005 → GPS'e %99 güvenir).
  /// Strava'nın 80 spike'ını kaldırır ama Strava gibi tüm hareketi yazar.
  /// Koşarken noktaları kaybetmez, sadece anlık GPS zıplamalarını düzeltir.
  static const GpsFilterParams stravaLight = GpsFilterParams(
    name: 'S2-MinKalman',
    color: Color(0xFFFF6D00),
    useKalman: true,
    kalmanLatLngQ: 0.0002,
    kalmanLatLngR: 0.0005,
    accuracyThreshold: 20.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 150.0,
    warmUpCount: 3,
    warmUpMinDistance: 0.5,
    postWarmUpMinDistance: 0.5,
    stationarySpeedThreshold: 0.3,
    poorAccuracyThreshold: 20.0,
  );

  /// V1 — Spike Guard: Kalman yok + ham GPS koordinat spike tespiti.
  /// Kalman'dan önce: eğer raw GPS koordinatı 10 m/s+ hızda zıpladıysa → at.
  /// 180° geri dönüş: normal koşu hızında (<7 m/s) → güvenle kabul edilir.
  /// GPS spike: 50m/saniye → reddedilir.
  /// Bel bandı: GPS koordinat tabanlı, ivmeölçer yok → sorunsuz.
  static const GpsFilterParams spikeGuard = GpsFilterParams(
    name: 'V1-SpikeGuard',
    color: Color(0xFF9C27B0),
    useKalman: false,
    rawSpikeSpeedMs: 10.0,
    accuracyThreshold: 20.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 150.0,
    warmUpCount: 3,
    warmUpMinDistance: 0.5,
    postWarmUpMinDistance: 0.5,
    stationarySpeedThreshold: 0.3,
    poorAccuracyThreshold: 20.0,
  );

  /// V2 — IIR Adaptive: Akademik makaledeki state machine + çift IIR yaklaşımı.
  /// 3 durum, GPS Doppler hızıyla tespit edilir (ivmeölçer değil):
  ///   STOP       (hız < 0.3 m/s) → pozisyonu dondur, mesafeye ekleme
  ///   PACE_CHANGE (|Δhız| > 0.8 m/s) → alpha=0.7 hafif smooth, hızlı tepki
  ///   STEADY_RUN  (sabit hız)    → alpha=0.3 güçlü smooth, GPS gürültüsü bastır
  /// Bel bandı uyumlu: GPS Doppler hızı telefon yöneliminden etkilenmez,
  /// yukarı-aşağı zıplama state'i bozmuyor.
  /// PMC makalesi: bu yöntem %70 mesafe hatası, %80 hız hatası azaltıyor.
  static const GpsFilterParams iirAdaptive = GpsFilterParams(
    name: 'V2-IIRAdaptif',
    color: Color(0xFF00BCD4),
    useKalman: false,
    useAdaptiveIir: true,
    iirAlphaSteady: 0.3,
    iirAlphaPaceChange: 0.7,
    speedChangeThresholdMs: 0.8,
    rawSpikeSpeedMs: 10.0,
    accuracyThreshold: 20.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 150.0,
    warmUpCount: 3,
    warmUpMinDistance: 0.5,
    postWarmUpMinDistance: 0.5,
    stationarySpeedThreshold: 0.3,
    poorAccuracyThreshold: 20.0,
  );

  static const List<GpsFilterParams> allPresets = [
    raw,
    current,
    aggressiveKalman,
    lenient,
    strict,
    stravaRaw,
    stravaLight,
    spikeGuard,
    iirAdaptive,
  ];

  GpsFilterParams copyWith({
    String? name,
    Color? color,
    bool? useKalman,
    double? kalmanLatLngQ,
    double? kalmanLatLngR,
    double? accuracyThreshold,
    double? maxSpeedKmh,
    double? maxImpliedSpeedKmh,
    int? warmUpCount,
    double? warmUpMinDistance,
    double? postWarmUpMinDistance,
    double? stationarySpeedThreshold,
    double? poorAccuracyThreshold,
    double? rawSpikeSpeedMs,
    bool? useAdaptiveIir,
    double? iirAlphaSteady,
    double? iirAlphaPaceChange,
    double? speedChangeThresholdMs,
    double? iirAlphaStop,
  }) {
    return GpsFilterParams(
      name: name ?? this.name,
      color: color ?? this.color,
      useKalman: useKalman ?? this.useKalman,
      kalmanLatLngQ: kalmanLatLngQ ?? this.kalmanLatLngQ,
      kalmanLatLngR: kalmanLatLngR ?? this.kalmanLatLngR,
      accuracyThreshold: accuracyThreshold ?? this.accuracyThreshold,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      maxImpliedSpeedKmh: maxImpliedSpeedKmh ?? this.maxImpliedSpeedKmh,
      warmUpCount: warmUpCount ?? this.warmUpCount,
      warmUpMinDistance: warmUpMinDistance ?? this.warmUpMinDistance,
      postWarmUpMinDistance: postWarmUpMinDistance ?? this.postWarmUpMinDistance,
      stationarySpeedThreshold: stationarySpeedThreshold ?? this.stationarySpeedThreshold,
      poorAccuracyThreshold: poorAccuracyThreshold ?? this.poorAccuracyThreshold,
      rawSpikeSpeedMs: rawSpikeSpeedMs ?? this.rawSpikeSpeedMs,
      useAdaptiveIir: useAdaptiveIir ?? this.useAdaptiveIir,
      iirAlphaSteady: iirAlphaSteady ?? this.iirAlphaSteady,
      iirAlphaPaceChange: iirAlphaPaceChange ?? this.iirAlphaPaceChange,
      speedChangeThresholdMs: speedChangeThresholdMs ?? this.speedChangeThresholdMs,
      iirAlphaStop: iirAlphaStop ?? this.iirAlphaStop,
    );
  }

  static const List<Color> selectableColors = [
    Color(0xFF9E9E9E),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
  ];
}

