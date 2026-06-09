import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ev PC — `serve-apk` / `fast-phone -Serve` (port 8877, version.json).
abstract final class TailscaleApkUpdate {
  static const prefsKey = 'tailscale_apk_base_url';
  static const defaultPort = 8877;

  static Future<String?> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(prefsKey)?.trim();
    if (v == null || v.isEmpty) return null;
    return _normalizeBase(v);
  }

  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final n = _normalizeBase(url.trim());
    if (n.isEmpty) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setString(prefsKey, n);
    }
  }

  /// `100.x.x.x` veya tam URL → `http://host:8877`
  static String baseFromHost(String host, {int port = defaultPort}) {
    var h = host.trim();
    if (h.isEmpty) return '';
    if (h.startsWith('http://') || h.startsWith('https://')) {
      return _normalizeBase(h);
    }
    final slash = h.indexOf('/');
    if (slash > 0) h = h.substring(0, slash);
    return 'http://$h:$port';
  }

  static String _normalizeBase(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return '';
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static Future<bool> _ensureInstallPermission() async {
    if (!Platform.isAndroid) return true;
    if ((await Permission.requestInstallPackages.status).isGranted) {
      return true;
    }
    final r = await Permission.requestInstallPackages.request();
    if (r.isGranted) return true;
    await openAppSettings();
    return false;
  }

  /// Tek dokunuş — arka plan / periyodik kontrol yok.
  static Future<TailscaleUpdateResult> updateNow({String? baseUrl}) async {
    if (kDebugMode) {
      return TailscaleUpdateResult.debugBuild;
    }
    if (!Platform.isAndroid) {
      return TailscaleUpdateResult.failed;
    }

    final base = _normalizeBase(baseUrl ?? (await loadBaseUrl()) ?? '');
    if (base.isEmpty) {
      return TailscaleUpdateResult.noServerUrl;
    }

    if (!await _ensureInstallPermission()) {
      return TailscaleUpdateResult.installPermissionNeeded;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final localCode = int.tryParse(info.buildNumber) ?? 0;

      final manifest = await _getJson('$base/version.json');
      if (manifest == null) {
        return TailscaleUpdateResult.serverUnreachable;
      }

      final remoteCode = manifest['versionCode'] is int
          ? manifest['versionCode'] as int
          : int.tryParse('${manifest['versionCode']}') ?? 0;

      if (remoteCode <= localCode) {
        return TailscaleUpdateResult.upToDate;
      }

      final apkPath = manifest['apkUrl']?.toString() ?? 'app.apk';
      final apkUrl = apkPath.startsWith('http') ? apkPath : '$base/$apkPath';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tailscale_update.apk');
      if (file.existsSync()) await file.delete();

      final ok = await _download(Uri.parse(apkUrl), file);
      if (!ok) return TailscaleUpdateResult.failed;

      final open = await OpenFilex.open(file.path);
      if (open.type == ResultType.done || open.type == ResultType.noAppToOpen) {
        return TailscaleUpdateResult.installStarted;
      }
      return TailscaleUpdateResult.failed;
    } catch (_) {
      return TailscaleUpdateResult.failed;
    }
  }

  static Future<Map<String, dynamic>?> _getJson(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', v));
      }
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> _download(Uri url, File dest) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(url);
      final res = await req.close();
      if (res.statusCode != 200) return false;
      final sink = dest.openWrite();
      await res.forEach(sink.add);
      await sink.close();
      return dest.lengthSync() > 0;
    } finally {
      client.close(force: true);
    }
  }
}

enum TailscaleUpdateResult {
  upToDate,
  installStarted,
  noServerUrl,
  serverUnreachable,
  installPermissionNeeded,
  debugBuild,
  failed,
}
