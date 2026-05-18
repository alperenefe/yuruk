import '../../domain/entities/named_track_segment.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';

class GpxExporter {
  static String toGpx(RunSession session) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln(
      '<gpx version="1.1" creator="Yürük" xmlns="http://www.topografix.com/GPX/1/1">',
    );
    sb.writeln('  <metadata>');
    sb.writeln('    <time>${DateTime.now().toUtc().toIso8601String()}</time>');
    sb.writeln('  </metadata>');

    if (session.rawTrackPoints.isNotEmpty) {
      _writeTrk(sb, 'Ham GPS (telefon)', session.rawTrackPoints);
    }
    for (final NamedTrackSegment seg in session.filterExportTracks) {
      if (seg.points.isNotEmpty) {
        _writeTrk(sb, seg.name, seg.points);
      }
    }
    if (session.rawTrackPoints.isEmpty &&
        session.filterExportTracks.every((s) => s.points.isEmpty) &&
        session.trackPoints.isNotEmpty) {
      _writeTrk(
        sb,
        'Rota',
        session.trackPoints,
      );
    }

    sb.writeln('</gpx>');
    return sb.toString();
  }

  static void _writeTrk(StringBuffer sb, String name, List<TrackPoint> points) {
    sb.writeln('  <trk>');
    sb.writeln('    <name>${_escapeXml(name)}</name>');
    sb.writeln('    <trkseg>');
    for (final p in points) {
      sb.writeln(
        '      <trkpt lat="${p.latitude}" lon="${p.longitude}">'
        '<ele>${p.altitude}</ele>'
        '<time>${p.timestamp.toUtc().toIso8601String()}</time>'
        '</trkpt>',
      );
    }
    sb.writeln('    </trkseg>');
    sb.writeln('  </trk>');
  }

  static String _escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
