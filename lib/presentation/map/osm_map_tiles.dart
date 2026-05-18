import 'package:flutter_map/flutter_map.dart';

final class OsmMapTiles {
  OsmMapTiles._();

  static const String urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static NetworkTileProvider createTileProvider() {
    return NetworkTileProvider(
      headers: {
        'User-Agent': 'Yuruk/1.0 (+https://github.com/alperenefe/yuruk)',
      },
    );
  }
}