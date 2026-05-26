import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/entities/track_point.dart';

void main() {
  group('TrackPoint', () {
    test('should calculate distance between two points correctly', () {
      final point1 = TrackPoint(
        latitude: 41.0082,
        longitude: 28.9784,
        altitude: 100,
        accuracy: 10,
        speed: 3.0,
        timestamp: DateTime.now(),
      );

      final point2 = TrackPoint(
        latitude: 41.0092,
        longitude: 28.9794,
        altitude: 100,
        accuracy: 10,
        speed: 3.0,
        timestamp: DateTime.now(),
      );

      final distance = point1.distanceTo(point2);
      
      expect(distance, greaterThan(100));
      expect(distance, lessThan(200));
    });
  });
}
