import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/core/filters/kalman_filter.dart';

void main() {
  group('KalmanFilter', () {
    test('should smooth noisy measurements', () {
      final filter = KalmanFilter();
      
      // Simulated noisy GPS readings around 39.9208
      final measurements = [39.9208, 39.9215, 39.9205, 39.9220, 39.9207];
      final results = measurements.map((m) => filter.filter(m)).toList();
      
      // Filtered values should be smoother (less variance)
      final variance = _calculateVariance(results);
      final rawVariance = _calculateVariance(measurements);
      
      expect(variance, lessThan(rawVariance));
    });

    test('should adjust to accuracy changes', () {
      final filter = KalmanFilter();
      
      // Good accuracy reading
      final result1 = filter.filter(39.9208, accuracy: 10.0);
      
      // Poor accuracy reading (should be weighted less)
      final result2 = filter.filter(39.9250, accuracy: 50.0);
      
      // Result should not jump too much due to poor accuracy
      expect((result2 - result1).abs(), lessThan(0.01));
    });

    test('should reset correctly', () {
      final filter = KalmanFilter(initialValue: 10.0);
      
      filter.filter(20.0);
      filter.reset(initialValue: 30.0);
      
      expect(filter.currentValue, equals(30.0));
    });
  });

  group('GpsKalmanFilter', () {
    test('should filter GPS coordinates', () {
      final filter = GpsKalmanFilter();
      
      final result = filter.filter(
        latitude: 39.9208,
        longitude: 32.8541,
        altitude: 850.0,
        speed: 2.5,
        accuracy: 15.0,
      );
      
      expect(result.length, equals(4));
      expect(result[0], isNotNull); // Filtered latitude
      expect(result[1], isNotNull); // Filtered longitude
      expect(result[2], isNotNull); // Filtered altitude
      expect(result[3], isNotNull); // Filtered speed
    });

    test('should smooth multiple GPS readings', () {
      final filter = GpsKalmanFilter();
      
      // Simulate GPS readings with noise
      final readings = [
        [39.9208, 32.8541, 850.0, 2.5],
        [39.9209, 32.8542, 851.0, 2.6],
        [39.9207, 32.8540, 849.0, 2.4],
      ];
      
      final results = readings.map((r) => filter.filter(
        latitude: r[0],
        longitude: r[1],
        altitude: r[2],
        speed: r[3],
        accuracy: 15.0,
      )).toList();
      
      // Should have same number of results
      expect(results.length, equals(readings.length));
      
      // Filtered values should be reasonable
      for (var result in results) {
        expect(result[0], inInclusiveRange(39.920, 39.921)); // Lat
        expect(result[1], inInclusiveRange(32.853, 32.855)); // Lng
      }
    });
  });
}

double _calculateVariance(List<double> values) {
  final mean = values.reduce((a, b) => a + b) / values.length;
  final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
  return squaredDiffs.reduce((a, b) => a + b) / values.length;
}
