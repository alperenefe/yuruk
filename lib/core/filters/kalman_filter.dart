/// Kalman Filter implementation for GPS data smoothing
/// 
/// Reduces GPS noise and improves tracking accuracy by estimating
/// the true position based on measurements and predictions.
class KalmanFilter {
  double _q; // Process noise covariance
  double _r; // Measurement noise covariance
  double _p; // Estimation error covariance
  double _x; // Estimated value
  double _k; // Kalman gain
  bool _isInitialized = false;

  KalmanFilter({
    double processNoise = 0.001,
    double measurementNoise = 0.01,
    double estimationError = 1.0,
    double initialValue = 0.0,
  })  : _q = processNoise,
        _r = measurementNoise,
        _p = estimationError,
        _x = initialValue,
        _k = 0.0;

  /// Apply filter to a new measurement
  /// 
  /// [measurement] - New GPS reading (lat, lng, or altitude)
  /// [accuracy] - GPS accuracy in meters (optional, adjusts measurement noise)
  /// 
  /// Returns filtered value
  double filter(double measurement, {double? accuracy}) {
    // Initialize with first measurement
    if (!_isInitialized) {
      _x = measurement;
      _isInitialized = true;
      return _x;
    }

    // Adjust measurement noise based on GPS accuracy
    if (accuracy != null && accuracy > 0) {
      // Worse accuracy = higher noise
      _r = 0.001 + (accuracy / 100.0);
    }

    // Prediction step
    _p = _p + _q;

    // Update step
    _k = _p / (_p + _r);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;

    return _x;
  }

  /// Reset filter to initial state
  void reset({double? initialValue}) {
    _p = 1.0;
    _x = initialValue ?? 0.0;
    _k = 0.0;
    _isInitialized = initialValue != null;
  }

  /// Get current estimated value without updating
  double get currentValue => _x;
}

/// GPS-specific Kalman Filter for latitude, longitude, and altitude
class GpsKalmanFilter {
  late KalmanFilter _latFilter;
  late KalmanFilter _lngFilter;
  late KalmanFilter _altFilter;
  late KalmanFilter _speedFilter;

  GpsKalmanFilter() {
    reset();
  }

  /// Filter a GPS position
  /// 
  /// Returns filtered [latitude, longitude, altitude, speed]
  List<double> filter({
    required double latitude,
    required double longitude,
    required double altitude,
    required double speed,
    double? accuracy,
  }) {
    return [
      _latFilter.filter(latitude, accuracy: accuracy),
      _lngFilter.filter(longitude, accuracy: accuracy),
      _altFilter.filter(altitude, accuracy: accuracy != null ? accuracy * 2 : null),
      _speedFilter.filter(speed, accuracy: accuracy != null ? accuracy / 10 : null),
    ];
  }

  /// Reset all filters
  void reset() {
    _latFilter = KalmanFilter(
      processNoise: 0.0001,
      measurementNoise: 0.01,
    );
    _lngFilter = KalmanFilter(
      processNoise: 0.0001,
      measurementNoise: 0.01,
    );
    _altFilter = KalmanFilter(
      processNoise: 0.001,
      measurementNoise: 0.05, // Altitude is less accurate
    );
    _speedFilter = KalmanFilter(
      processNoise: 0.0005,
      measurementNoise: 0.02,
    );
  }
}
