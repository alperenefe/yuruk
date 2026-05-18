import 'dart:io';
import 'dart:math';
import 'package:xml/xml.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Kullanım: dart run bin/compare_gpx.dart <dosya.gpx>');
    exit(1);
  }
  final file = File(args[0]);
  if (!file.existsSync()) {
    print('Dosya bulunamadı: ${args[0]}');
    exit(1);
  }
  final gpxXml = file.readAsStringSync();
  _run(gpxXml, args[0]);
}

void _run(String gpxXml, String fileName) {
  final rawPoints = _parseGpx(gpxXml);
  print('\n📂 Dosya : $fileName');
  print('📍 Ham nokta sayısı: ${rawPoints.length}\n');

  final configs = _presetConfigs();
  final results = configs.map((c) => _runPipeline(c, rawPoints)).toList();

  _printTable(results);

  final htmlPath = '${fileName.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '')}_comparison.html';
  _writeHtml(htmlPath, results, rawPoints, fileName);
  print('\n🗺️  HTML rapor: $htmlPath');
  print('   Tarayıcıda açmak için: start $htmlPath\n');
}

// ─── Veri modelleri ──────────────────────────────────────────────────────────

class _Point {
  final double lat, lng, alt, accuracy, speed;
  final DateTime time;
  _Point(this.lat, this.lng, this.alt, this.accuracy, this.speed, this.time);

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

class _Config {
  final String name;
  final bool useKalman;
  final double kalmanQ, kalmanR;
  final double accuracyThreshold, maxSpeedKmh, maxImpliedSpeedKmh;
  final int warmUpCount;
  final double warmUpMinDist, postWarmUpMinDist;
  final double stationarySpeed, poorAccuracy;

  const _Config({
    required this.name,
    this.useKalman = true,
    this.kalmanQ = 0.0001,
    this.kalmanR = 0.01,
    this.accuracyThreshold = 25,
    this.maxSpeedKmh = 50,
    this.maxImpliedSpeedKmh = 100,
    this.warmUpCount = 10,
    this.warmUpMinDist = 2,
    this.postWarmUpMinDist = 5,
    this.stationarySpeed = 0.5,
    this.poorAccuracy = 15,
  });
}

class _Result {
  final _Config config;
  final List<_Point> points;
  final int rawCount, rejectedCount;
  final double totalDistance;

  _Result({
    required this.config,
    required this.points,
    required this.rawCount,
    required this.rejectedCount,
    required this.totalDistance,
  });

  int get accepted => rawCount - rejectedCount;
  double get retention => rawCount == 0 ? 0 : accepted / rawCount;

  double get smoothness {
    if (points.length < 3) return 0;
    double total = 0;
    for (int i = 1; i < points.length - 1; i++) {
      final b1 = _bearing(points[i - 1], points[i]);
      final b2 = _bearing(points[i], points[i + 1]);
      total += _angleDiff(b1, b2);
    }
    return total;
  }

  String get smoothLabel {
    final s = smoothness;
    if (s < 500) return 'Çok Düzgün ✅';
    if (s < 1500) return 'Düzgün ✅';
    if (s < 3000) return 'Orta ⚠️';
    return 'Gürültülü ❌';
  }

  String get distFmt {
    if (totalDistance >= 1000) {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
    return '${totalDistance.toStringAsFixed(0)} m';
  }
}

// ─── Preset config'ler ───────────────────────────────────────────────────────

List<_Config> _presetConfigs() => [
      const _Config(
        name: 'Ham (filtresiz)',
        useKalman: false,
        accuracyThreshold: 9999,
        maxSpeedKmh: 9999,
        maxImpliedSpeedKmh: 9999,
        warmUpCount: 0,
        warmUpMinDist: 0,
        postWarmUpMinDist: 0,
        stationarySpeed: 0,
        poorAccuracy: 9999,
      ),
      const _Config(name: 'Mevcut'),
      const _Config(
        name: 'Güçlü Kalman',
        kalmanQ: 0.00001,
        kalmanR: 0.001,
      ),
      const _Config(
        name: 'Toleranslı',
        accuracyThreshold: 50,
        maxSpeedKmh: 70,
        maxImpliedSpeedKmh: 150,
        warmUpCount: 5,
        warmUpMinDist: 1,
        postWarmUpMinDist: 3,
        stationarySpeed: 0.3,
        poorAccuracy: 25,
      ),
      const _Config(
        name: 'Katı',
        accuracyThreshold: 12,
        maxSpeedKmh: 35,
        maxImpliedSpeedKmh: 70,
        warmUpCount: 15,
        warmUpMinDist: 3,
        postWarmUpMinDist: 8,
        stationarySpeed: 0.8,
        poorAccuracy: 10,
      ),
    ];

// ─── GPX parser ──────────────────────────────────────────────────────────────

List<_Point> _parseGpx(String xml) {
  final doc = XmlDocument.parse(xml);
  final trkpts = doc.findAllElements('trkpt');
  final raw = <_Point>[];

  for (final t in trkpts) {
    final lat = double.tryParse(t.getAttribute('lat') ?? '');
    final lng = double.tryParse(t.getAttribute('lon') ?? '');
    if (lat == null || lng == null) continue;
    final alt = double.tryParse(t.findElements('ele').firstOrNull?.innerText ?? '') ?? 0.0;
    final timeStr = t.findElements('time').firstOrNull?.innerText ?? '';
    final time = DateTime.tryParse(timeStr) ?? DateTime.now();
    raw.add(_Point(lat, lng, alt, 5.0, 0.0, time));
  }

  // Hız çıkar
  final result = <_Point>[];
  result.add(raw.first);
  for (int i = 1; i < raw.length; i++) {
    final prev = raw[i - 1], curr = raw[i];
    final dist = prev.distanceTo(curr);
    final dt = curr.time.difference(prev.time).inSeconds.abs();
    final speed = dt > 0 ? dist / dt : 0.0;
    result.add(_Point(curr.lat, curr.lng, curr.alt, curr.accuracy, speed, curr.time));
  }
  return result;
}

// ─── Kalman filtresi ──────────────────────────────────────────────────────────

class _Kalman {
  final double q, r;
  double _p = 1, _x = 0, _k = 0;
  bool _init = false;

  _Kalman(this.q, this.r);

  double filter(double m, {double? acc}) {
    if (!_init) { _x = m; _init = true; return _x; }
    final effR = acc != null && acc > 0 ? 0.001 + acc / 100.0 : r;
    _p += q;
    _k = _p / (_p + effR);
    _x += _k * (m - _x);
    _p = (1 - _k) * _p;
    return _x;
  }
}

// ─── Pipeline ────────────────────────────────────────────────────────────────

_Result _runPipeline(_Config cfg, List<_Point> raw) {
  final latK = _Kalman(cfg.kalmanQ, cfg.kalmanR);
  final lngK = _Kalman(cfg.kalmanQ, cfg.kalmanR);
  final filtered = <_Point>[];
  int rejected = 0;
  double dist = 0;

  for (final p in raw) {
    final warmUp = filtered.length < cfg.warmUpCount;

    if (!warmUp) {
      if (p.accuracy > cfg.accuracyThreshold) { rejected++; continue; }
      if (p.speed * 3.6 > cfg.maxSpeedKmh) { rejected++; continue; }
      if (p.speed < cfg.stationarySpeed && p.accuracy > cfg.poorAccuracy) {
        rejected++; continue;
      }
    }

    final lat = cfg.useKalman ? latK.filter(p.lat, acc: p.accuracy) : p.lat;
    final lng = cfg.useKalman ? lngK.filter(p.lng, acc: p.accuracy) : p.lng;
    final fp = _Point(lat, lng, p.alt, p.accuracy, p.speed, p.time);

    if (filtered.isNotEmpty) {
      final d = filtered.last.distanceTo(fp);
      final minD = warmUp ? cfg.warmUpMinDist : cfg.postWarmUpMinDist;
      if (d < minD && p.speed < cfg.stationarySpeed) { rejected++; continue; }

      if (filtered.length >= 2) {
        final dt = fp.time.difference(filtered.last.time).inSeconds;
        if (dt > 0 && (d / dt) * 3.6 > cfg.maxImpliedSpeedKmh) {
          rejected++; continue;
        }
      }
      dist += d;
    }
    filtered.add(fp);
  }

  return _Result(
    config: cfg,
    points: filtered,
    rawCount: raw.length,
    rejectedCount: rejected,
    totalDistance: dist,
  );
}

// ─── Konsol çıktısı ──────────────────────────────────────────────────────────

void _printTable(List<_Result> results) {
  final w = [20, 10, 10, 10, 8, 16, 16];
  final sep = w.map((n) => '-' * (n + 2)).join('+');

  String cell(String s, int width) {
    if (s.length > width) s = s.substring(0, width - 1) + '…';
    return ' ${s.padRight(width)} ';
  }

  print(' $sep');
  print(
    '|${cell("Config", w[0])}|${cell("Mesafe", w[1])}|'
    '${cell("Nokta", w[2])}|${cell("Red.", w[3])}|'
    '${cell("%Tut.", w[4])}|${cell("Düzgünlük", w[5])}|'
    '${cell("Smoothness", w[6])}|',
  );
  print(' $sep');
  for (final r in results) {
    print(
      '|${cell(r.config.name, w[0])}|${cell(r.distFmt, w[1])}|'
      '${cell('${r.accepted}', w[2])}|${cell('${r.rejectedCount}', w[3])}|'
      '${cell('%${(r.retention * 100).toStringAsFixed(0)}', w[4])}|'
      '${cell(r.smoothLabel, w[5])}|'
      '${cell(r.smoothness.toStringAsFixed(0), w[6])}|',
    );
  }
  print(' $sep\n');
}

// ─── HTML rapor ──────────────────────────────────────────────────────────────

const _colors = ['#9E9E9E', '#2196F3', '#4CAF50', '#FF9800', '#F44336'];

void _writeHtml(String path, List<_Result> results, List<_Point> raw, String fileName) {
  final sb = StringBuffer();

  sb.write('''<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<title>GPS Karşılaştırma – $fileName</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, sans-serif; background: #f5f5f5; }
  h1 { padding: 14px 20px; font-size: 16px; background: #1976D2; color: #fff; }
  #map { width: 100%; height: calc(100vh - 200px); }
  #stats { display: flex; flex-wrap: wrap; gap: 10px; padding: 12px 16px; background: #fff; border-top: 1px solid #ddd; }
  .card { border-radius: 8px; padding: 10px 14px; min-width: 160px; border: 2px solid; }
  .card h3 { font-size: 13px; margin-bottom: 6px; }
  .card p { font-size: 12px; color: #555; line-height: 1.7; }
  .badge { display: inline-block; padding: 1px 6px; border-radius: 4px; font-size: 11px; font-weight: 600; margin-top: 3px; }
  .good { background: #e8f5e9; color: #2e7d32; }
  .mid  { background: #fff3e0; color: #e65100; }
  .bad  { background: #ffebee; color: #c62828; }
</style>
</head>
<body>
<h1>GPS Algoritma Karşılaştırması – $fileName &nbsp;·&nbsp; ${raw.length} ham nokta</h1>
<div id="map"></div>
<div id="stats">
''');

  for (int i = 0; i < results.length; i++) {
    final r = results[i];
    final color = i < _colors.length ? _colors[i] : '#607D8B';
    final badgeClass = r.smoothness < 1500 ? 'good' : r.smoothness < 3000 ? 'mid' : 'bad';
    sb.write('''
  <div class="card" style="border-color:$color">
    <h3 style="color:$color">${r.config.name}</h3>
    <p>
      📏 ${r.distFmt}<br>
      📍 ${r.accepted} nokta / ${r.rejectedCount} red.<br>
      🎯 %${(r.retention * 100).toStringAsFixed(0)} tutuldu<br>
      <span class="badge $badgeClass">${r.smoothLabel}</span>
    </p>
  </div>''');
  }

  sb.write('\n</div>\n<script>\n');
  sb.write('var map = L.map("map");\n');
  sb.write('L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{maxZoom:19}).addTo(map);\n');

  for (int i = 0; i < results.length; i++) {
    final r = results[i];
    final color = i < _colors.length ? _colors[i] : '#607D8B';
    if (r.points.isEmpty) continue;
    final pts = r.points.map((p) => '[${p.lat},${p.lng}]').join(',');
    sb.write('L.polyline([$pts],{color:"$color",weight:3.5,opacity:0.85}).addTo(map);\n');
  }

  // Haritayı ilk sonucun noktalarına göre fit et
  final fitPoints = results.firstWhere((r) => r.points.isNotEmpty, orElse: () => results.first);
  if (fitPoints.points.isNotEmpty) {
    final lats = fitPoints.points.map((p) => p.lat);
    final lngs = fitPoints.points.map((p) => p.lng);
    sb.write('map.fitBounds([[${lats.reduce(min)},${lngs.reduce(min)}],[${lats.reduce(max)},${lngs.reduce(max)}]],{padding:[20,20]});\n');
  }

  // Legend
  sb.write('''
var legend = L.control({position:"topright"});
legend.onAdd = function(){
  var d = L.DomUtil.create("div","");
  d.style.cssText="background:rgba(255,255,255,0.92);padding:8px 12px;border-radius:8px;font:12px system-ui;line-height:2";
''');
  for (int i = 0; i < results.length; i++) {
    final color = i < _colors.length ? _colors[i] : '#607D8B';
    sb.write('  d.innerHTML+="<span style=\\"display:inline-block;width:18px;height:4px;background:$color;border-radius:2px;vertical-align:middle;margin-right:6px\\"></span>${results[i].config.name}<br>";\n');
  }
  sb.write('  return d;\n};\nlegend.addTo(map);\n');

  sb.write('</script>\n</body>\n</html>\n');

  File(path).writeAsStringSync(sb.toString());
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
