import 'package:xml/xml.dart';
import '../../domain/entities/track_point.dart';

class GpxParseException implements Exception {
  final String message;
  const GpxParseException(this.message);
  @override
  String toString() => 'GpxParseException: $message';
}

class GpxImporter {
  List<TrackPoint> parse(String gpxXml) {
    late XmlDocument doc;
    try {
      doc = XmlDocument.parse(gpxXml);
    } catch (e) {
      throw GpxParseException('Geçersiz GPX dosyası: $e');
    }

    final trkpts = doc.findAllElements('trkpt');
    if (trkpts.isEmpty) {
      throw const GpxParseException('GPX dosyasında track noktası bulunamadı');
    }

    final points = <TrackPoint>[];

    for (final trkpt in trkpts) {
      final latStr = trkpt.getAttribute('lat');
      final lonStr = trkpt.getAttribute('lon');

      if (latStr == null || lonStr == null) continue;

      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat == null || lon == null) continue;

      final eleEl = trkpt.findElements('ele').firstOrNull;
      final altitude = double.tryParse(eleEl?.innerText ?? '') ?? 0.0;

      final timeEl = trkpt.findElements('time').firstOrNull;
      DateTime? timestamp;
      if (timeEl != null) {
        timestamp = DateTime.tryParse(timeEl.innerText);
      }

      final extensions = trkpt.findElements('extensions').firstOrNull;
      double speed = 0.0;
      double accuracy = 5.0;

      if (extensions != null) {
        final speedEl = extensions.findAllElements('speed').firstOrNull ??
            extensions.findAllElements('gpxtpx:speed').firstOrNull;
        if (speedEl != null) {
          speed = double.tryParse(speedEl.innerText) ?? 0.0;
        }

        final accEl = extensions.findAllElements('accuracy').firstOrNull ??
            extensions.findAllElements('gpxtpx:accuracy').firstOrNull;
        if (accEl != null) {
          accuracy = double.tryParse(accEl.innerText) ?? 5.0;
        }
      }

      points.add(TrackPoint(
        latitude: lat,
        longitude: lon,
        altitude: altitude,
        accuracy: accuracy,
        speed: speed,
        timestamp: timestamp ?? DateTime.now(),
      ));
    }

    if (points.isEmpty) {
      throw const GpxParseException('Geçerli nokta okunamadı');
    }

    final withSpeed = _inferSpeeds(points);
    return withSpeed;
  }

  List<TrackPoint> _inferSpeeds(List<TrackPoint> points) {
    if (points.length < 2) return points;

    final result = <TrackPoint>[];
    result.add(points.first);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      double speed = curr.speed;

      if (speed == 0) {
        final dist = prev.distanceTo(curr);
        final timeDiff =
            curr.timestamp.difference(prev.timestamp).inSeconds.abs();
        if (timeDiff > 0) {
          speed = dist / timeDiff;
        }
      }

      result.add(TrackPoint(
        latitude: curr.latitude,
        longitude: curr.longitude,
        altitude: curr.altitude,
        accuracy: curr.accuracy,
        speed: speed,
        bearing: curr.bearing,
        timestamp: curr.timestamp,
      ));
    }

    return result;
  }
}
