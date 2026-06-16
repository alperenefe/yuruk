import 'dart:io';
import 'dart:math';

import 'package:xml/xml.dart';

void main(List<String> args) {
  if (args.length < 2) {
    print('Kullanım: dart run bin/compare_strava_yuruk.dart <strava.gpx> <yuruk.gpx>');
    exit(1);
  }
  final stravaPath = args[0];
  final yurukPath = args[1];
  for (final p in [stravaPath, yurukPath]) {
    if (!File(p).existsSync()) {
      print('Dosya yok: $p');
      exit(1);
    }
  }

  final strava = _loadGpx(stravaPath, label: 'Strava');
  final yuruk = _loadGpx(yurukPath, label: 'Yürük');

  _printReport(strava, yuruk, stravaPath, yurukPath);

  final htmlPath = yurukPath.replaceAll(
    RegExp(r'\.gpx$', caseSensitive: false),
    '_vs_strava.html',
  );
  _writeHtml(htmlPath, strava, yuruk, stravaPath, yurukPath);
  print('\n🗺️  HTML: $htmlPath');
}

class _Track {
  final String label;
  final String name;
  final List<_Point> points;

  _Track({required this.label, required this.name, required this.points});
}

class _Point {
  final double lat, lng, alt;
  final DateTime time;

  _Point(this.lat, this.lng, this.alt, this.time);

  double distanceTo(_Point o) {
    const r = 6371000.0;
    final lat1 = lat * pi / 180, lat2 = o.lat * pi / 180;
    final dLat = (o.lat - lat) * pi / 180;
    final dLon = (o.lng - lng) * pi / 180;
    final a = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    return r * 2 * asin(sqrt(a));
  }
}

class _Stats {
  final int pointCount;
  final double distanceM;
  final Duration duration;
  final double avgIntervalSec;
  final double smoothness;

  _Stats({
    required this.pointCount,
    required this.distanceM,
    required this.duration,
    required this.avgIntervalSec,
    required this.smoothness,
  });

  String get distKm => '${(distanceM / 1000).toStringAsFixed(2)} km';
  String get durFmt {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '${m}dk ${s.toString().padLeft(2, '0')}sn';
  }
}

_Track _loadGpx(String path, {required String label}) {
  final xml = File(path).readAsStringSync();
  final doc = XmlDocument.parse(xml);
  final trks = doc.findAllElements('trk');
  if (trks.isEmpty) {
    return _Track(label: label, name: path, points: []);
  }
  final trk = trks.first;
  final name = trk.findElements('name').firstOrNull?.innerText ?? label;
  final pts = <_Point>[];
  for (final t in trk.findAllElements('trkpt')) {
    final lat = double.tryParse(t.getAttribute('lat') ?? '');
    final lng = double.tryParse(t.getAttribute('lon') ?? '');
    if (lat == null || lng == null) continue;
    final alt =
        double.tryParse(t.findElements('ele').firstOrNull?.innerText ?? '') ??
            0.0;
    final timeStr = t.findElements('time').firstOrNull?.innerText ?? '';
    final time = DateTime.tryParse(timeStr) ?? DateTime.now();
    pts.add(_Point(lat, lng, alt, time));
  }
  return _Track(label: label, name: name, points: pts);
}

_Stats _stats(List<_Point> pts) {
  if (pts.isEmpty) {
    return _Stats(
      pointCount: 0,
      distanceM: 0,
      duration: Duration.zero,
      avgIntervalSec: 0,
      smoothness: 0,
    );
  }
  double dist = 0;
  for (int i = 1; i < pts.length; i++) {
    dist += pts[i - 1].distanceTo(pts[i]);
  }
  final dur = pts.last.time.difference(pts.first.time);
  double intervalSum = 0;
  for (int i = 1; i < pts.length; i++) {
    intervalSum += pts[i].time.difference(pts[i - 1].time).inMilliseconds / 1000;
  }
  final avgInt = pts.length > 1 ? intervalSum / (pts.length - 1) : 0;
  return _Stats(
    pointCount: pts.length,
    distanceM: dist,
    duration: dur,
    avgIntervalSec: avgInt.toDouble(),
    smoothness: _smoothness(pts),
  );
}

double _smoothness(List<_Point> pts) {
  if (pts.length < 3) return 0;
  double total = 0;
  for (int i = 1; i < pts.length - 1; i++) {
    final b1 = _bearing(pts[i - 1], pts[i]);
    final b2 = _bearing(pts[i], pts[i + 1]);
    total += _angleDiff(b1, b2);
  }
  return total;
}

double _bearing(_Point a, _Point b) {
  final dLon = (b.lng - a.lng) * pi / 180;
  final lat1 = a.lat * pi / 180, lat2 = b.lat * pi / 180;
  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  return atan2(y, x) * 180 / pi;
}

double _angleDiff(double a, double b) {
  double d = (b - a).abs() % 360;
  if (d > 180) d = 360 - d;
  return d;
}

/// Her nokta için karşı izdeki en yakın noktaya mesafe (m).
List<double> _nearestDists(List<_Point> from, List<_Point> to) {
  if (from.isEmpty || to.isEmpty) return [];
  final out = <double>[];
  for (final p in from) {
    var best = double.infinity;
    for (final q in to) {
      final d = p.distanceTo(q);
      if (d < best) best = d;
    }
    out.add(best);
  }
  return out;
}

double _percentile(List<double> vals, double p) {
  if (vals.isEmpty) return 0;
  final sorted = List<double>.from(vals)..sort();
  final idx = ((sorted.length - 1) * p).round();
  return sorted[idx.clamp(0, sorted.length - 1)];
}

/// Zaman hizalı mesafe farkı: her Yürük noktasında Strava'daki en yakın zamana göre kümülatif mesafe.
Map<String, double> _timeAlignedDistanceGap(_Track strava, _Track yuruk) {
  if (strava.points.isEmpty || yuruk.points.isEmpty) return {};

  double stravaCum = 0;
  double yurukCum = 0;
  int si = 0;
  final gaps = <double>[];

  for (int yi = 1; yi < yuruk.points.length; yi++) {
    yurukCum += yuruk.points[yi - 1].distanceTo(yuruk.points[yi]);
    final t = yuruk.points[yi].time;

    while (si + 1 < strava.points.length &&
        strava.points[si + 1].time.isBefore(t)) {
      si++;
      stravaCum +=
          strava.points[si - 1].distanceTo(strava.points[si]);
    }
    gaps.add(yurukCum - stravaCum);
  }

  if (gaps.isEmpty) return {};
  gaps.sort();
  return {
    'son_fark_m': gaps.last,
    'ort_fark_m': gaps.reduce((a, b) => a + b) / gaps.length,
    'medyan_fark_m': gaps[gaps.length ~/ 2],
  };
}

void _printReport(
  _Track strava,
  _Track yuruk,
  String stravaPath,
  String yurukPath,
) {
  final ss = _stats(strava.points);
  final ys = _stats(yuruk.points);

  final y2s = _nearestDists(yuruk.points, strava.points);
  final s2y = _nearestDists(strava.points, yuruk.points);
  final gap = _timeAlignedDistanceGap(strava, yuruk);

  final distDiff = ys.distanceM - ss.distanceM;
  final distDiffPct =
      ss.distanceM > 0 ? (distDiff / ss.distanceM) * 100 : 0.0;

  print('\n${'═' * 60}');
  print('  STRAVA vs YÜRÜK KARŞILAŞTIRMA');
  print('${'═' * 60}');
  print('Strava : $stravaPath');
  print('         ${strava.name}');
  print('Yürük  : $yurukPath');
  print('         ${yuruk.name}');
  print('${'─' * 60}');

  print('\n📊 TEMEL METRİKLER');
  _row('Mesafe', ss.distKm, ys.distKm,
      delta: '${distDiff >= 0 ? '+' : ''}${(distDiff / 1000).toStringAsFixed(2)} km (${distDiffPct >= 0 ? '+' : ''}${distDiffPct.toStringAsFixed(1)}%)');
  _row('Süre', ss.durFmt, ys.durFmt);
  _row('Nokta sayısı', '${ss.pointCount}', '${ys.pointCount}');
  _row('Ort. örnekleme', '${ss.avgIntervalSec.toStringAsFixed(1)} sn',
      '${ys.avgIntervalSec.toStringAsFixed(1)} sn');
  _row('Düzgünlük (°)', ss.smoothness.toStringAsFixed(0),
      ys.smoothness.toStringAsFixed(0));

  print('\n📍 İZ SAPMASI (harita üst üste bindirme)');
  if (y2s.isNotEmpty) {
    final avgY = y2s.reduce((a, b) => a + b) / y2s.length;
    print('  Yürük → Strava en yakın nokta:');
    print('    ort=${avgY.toStringAsFixed(1)}m  medyan=${_percentile(y2s, 0.5).toStringAsFixed(1)}m  p95=${_percentile(y2s, 0.95).toStringAsFixed(1)}m  max=${y2s.reduce(max).toStringAsFixed(1)}m');
  }
  if (s2y.isNotEmpty) {
    final avgS = s2y.reduce((a, b) => a + b) / s2y.length;
    print('  Strava → Yürük en yakın nokta:');
    print('    ort=${avgS.toStringAsFixed(1)}m  medyan=${_percentile(s2y, 0.5).toStringAsFixed(1)}m  p95=${_percentile(s2y, 0.95).toStringAsFixed(1)}m  max=${s2y.reduce(max).toStringAsFixed(1)}m');
  }

  if (gap.isNotEmpty) {
    print('\n⏱️  ZAMAN HİZALI MESAFE FARKI (Yürük − Strava)');
    print('  Son: ${gap['son_fark_m']!.toStringAsFixed(0)} m');
    print('  Ort: ${gap['ort_fark_m']!.toStringAsFixed(0)} m');
    print('  Medyan: ${gap['medyan_fark_m']!.toStringAsFixed(0)} m');
  }

  if (strava.points.isNotEmpty && yuruk.points.isNotEmpty) {
    final startGap =
        strava.points.first.distanceTo(yuruk.points.first);
    final endGap = strava.points.last.distanceTo(yuruk.points.last);
    print('\n🚩 BAŞLANGIÇ / BİTİŞ');
    print('  Başlangıç farkı: ${startGap.toStringAsFixed(1)} m');
    print('  Bitiş farkı: ${endGap.toStringAsFixed(1)} m');
  }

  print('\n🎯 DEĞERLENDİRME');
  final avgDev = y2s.isEmpty ? 999.0 : y2s.reduce((a, b) => a + b) / y2s.length;
  if (avgDev < 5) {
    print('  ✅ İzler çok yakın — Strava ile neredeyse aynı rota.');
  } else if (avgDev < 15) {
    print('  ✅ İyi — tipik telefon GPS sapması aralığında.');
  } else if (avgDev < 30) {
    print('  ⚠️  Orta sapma — filtre veya örnekleme farkı olabilir.');
  } else {
    print('  ❌ Belirgin sapma — algoritma veya GPS kaynağı farklı.');
  }
  if (distDiffPct.abs() > 3) {
    print('  ⚠️  Mesafe farkı %${distDiffPct.abs().toStringAsFixed(1)} — filtre çok nokta kesiyor veya örnekleme seyrek.');
  } else {
    print('  ✅ Mesafe farkı kabul edilebilir (<%3).');
  }
  print('${'═' * 60}\n');
}

void _row(String label, String a, String b, {String? delta}) {
  print('  ${label.padRight(16)} Strava: ${a.padRight(12)} Yürük: $b${delta != null ? '  Δ $delta' : ''}');
}

void _writeHtml(
  String path,
  _Track strava,
  _Track yuruk,
  String stravaPath,
  String yurukPath,
) {
  final ss = _stats(strava.points);
  final ys = _stats(yuruk.points);
  final y2s = _nearestDists(yuruk.points, strava.points);
  final avgDev =
      y2s.isEmpty ? 0.0 : y2s.reduce((a, b) => a + b) / y2s.length;
  final distDiff = ys.distanceM - ss.distanceM;
  final distDiffPct =
      ss.distanceM > 0 ? (distDiff / ss.distanceM) * 100 : 0.0;

  String pts(List<_Point> p) =>
      p.map((x) => '[${x.lat},${x.lng}]').join(',');

  final sb = StringBuffer()
    ..writeln('<!DOCTYPE html><html lang="tr"><head><meta charset="UTF-8">')
    ..writeln('<title>Strava vs Yürük</title>')
    ..writeln(
        '<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>')
    ..writeln(
        '<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>')
    ..writeln('<style>body{margin:0;font-family:system-ui,sans-serif}')
    ..writeln(
        'h1{font-size:15px;padding:12px 16px;background:#FC4C02;color:#fff;margin:0}')
    ..writeln(
        '#stats{display:flex;flex-wrap:wrap;gap:10px;padding:12px;background:#f5f5f5;border-bottom:1px solid #ddd}')
    ..writeln(
        '.c{background:#fff;border-radius:8px;padding:10px 14px;min-width:180px;border-left:4px solid}')
    ..writeln('#map{height:calc(100vh - 180px)}</style></head><body>')
    ..writeln('<h1>Strava vs Yürük — ${yuruk.name}</h1>')
    ..writeln('<div id="stats">')
    ..writeln(
        '<div class="c" style="border-color:#FC4C02"><b>Strava</b><br>${ss.distKm} · ${ss.durFmt}<br>${ss.pointCount} nokta</div>')
    ..writeln(
        '<div class="c" style="border-color:#2196F3"><b>Yürük</b><br>${ys.distKm} · ${ys.durFmt}<br>${ys.pointCount} nokta</div>')
    ..writeln(
        '<div class="c" style="border-color:#4CAF50"><b>Fark</b><br>${distDiff >= 0 ? '+' : ''}${(distDiff).toStringAsFixed(0)} m (${distDiffPct >= 0 ? '+' : ''}${distDiffPct.toStringAsFixed(1)}%)<br>Ort sapma ${avgDev.toStringAsFixed(1)} m</div>')
    ..writeln('</div><div id="map"></div><script>')
    ..writeln('var map=L.map("map");')
    ..writeln(
        'L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png").addTo(map);');

  if (strava.points.isNotEmpty) {
    sb.writeln(
        'L.polyline([${pts(strava.points)}],{color:"#FC4C02",weight:4,opacity:0.9}).addTo(map);');
  }
  if (yuruk.points.isNotEmpty) {
    sb.writeln(
        'L.polyline([${pts(yuruk.points)}],{color:"#2196F3",weight:4,opacity:0.75,dashArray:"8 6"}).addTo(map);');
  }

  final all = [...strava.points, ...yuruk.points];
  if (all.isNotEmpty) {
    final lats = all.map((p) => p.lat);
    final lngs = all.map((p) => p.lng);
    sb.writeln(
        'map.fitBounds([[${lats.reduce(min)},${lngs.reduce(min)}],[${lats.reduce(max)},${lngs.reduce(max)}]],{padding:[30,30]});');
  }

  sb.writeln('</script></body></html>');
  File(path).writeAsStringSync(sb.toString());
}
