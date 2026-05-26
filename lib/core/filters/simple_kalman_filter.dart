/// Tek eksenli Kalman filtresi.
/// GPS lat/lng koordinatlarını bağımsız olarak düzleştirmek için kullanılır.
class SimpleKalmanFilter {
  final double q; // Süreç gürültüsü — küçük = modele güven
  final double r; // Ölçüm gürültüsü — büyük = GPS'e az güven

  double _p = 1.0;
  double _x = 0.0;
  double _k = 0.0;
  bool _initialized = false;

  SimpleKalmanFilter({required this.q, required this.r});

  /// [accuracy] sağlanırsa GPS doğruluğuna göre R dinamik ayarlanır.
  double filter(double measurement, {double? accuracy}) {
    if (!_initialized) {
      _x = measurement;
      _initialized = true;
      return _x;
    }
    final effectiveR =
        (accuracy != null && accuracy > 0) ? 0.001 + (accuracy / 100.0) : r;
    _p = _p + q;
    _k = _p / (_p + effectiveR);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;
    return _x;
  }

  void reset() {
    _p = 1.0;
    _x = 0.0;
    _k = 0.0;
    _initialized = false;
  }
}
