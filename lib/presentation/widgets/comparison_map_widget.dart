import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/filters/gps_filter_pipeline.dart';
import '../map/osm_map_tiles.dart';
import '../../domain/entities/track_point.dart';

class ComparisonMapWidget extends StatefulWidget {
  final List<FilteredTrackResult> results;
  final List<bool> visibleConfigs;
  final TrackPoint? centerPoint;

  const ComparisonMapWidget({
    super.key,
    required this.results,
    required this.visibleConfigs,
    this.centerPoint,
  });

  @override
  State<ComparisonMapWidget> createState() => _ComparisonMapWidgetState();
}

class _ComparisonMapWidgetState extends State<ComparisonMapWidget> {
  final MapController _mapController = MapController();
  final NetworkTileProvider _osmTileProvider = OsmMapTiles.createTileProvider();
  bool _isMapReady = false;

  LatLng get _center {
    if (widget.centerPoint != null) {
      return LatLng(widget.centerPoint!.latitude, widget.centerPoint!.longitude);
    }
    for (int i = 0; i < widget.results.length; i++) {
      final r = widget.results[i];
      if (r.points.isNotEmpty) {
        return LatLng(r.points.first.latitude, r.points.first.longitude);
      }
    }
    return const LatLng(39.9208, 32.8541);
  }

  void _fitBounds() {
    if (!_isMapReady) return;
    final allPoints = <LatLng>[];
    for (int i = 0; i < widget.results.length; i++) {
      if (i < widget.visibleConfigs.length && widget.visibleConfigs[i]) {
        allPoints.addAll(widget.results[i].points
            .map((p) => LatLng(p.latitude, p.longitude)));
      }
    }
    if (allPoints.isEmpty) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  @override
  void didUpdateWidget(ComparisonMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results && widget.results.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];

    for (int i = 0; i < widget.results.length; i++) {
      final visible = i < widget.visibleConfigs.length
          ? widget.visibleConfigs[i]
          : true;
      if (!visible) continue;

      final result = widget.results[i];
      if (result.points.isEmpty) continue;

      final latlngs =
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      polylines.add(Polyline(
        points: latlngs,
        strokeWidth: 3.5,
        color: result.params.color.withValues(alpha: 0.85),
      ));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 15.0,
            onMapReady: () {
              setState(() => _isMapReady = true);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _fitBounds());
            },
          ),
          children: [
            TileLayer(
              urlTemplate: OsmMapTiles.urlTemplate,
              userAgentPackageName: 'com.trendyol.yuruk.yuruk',
              tileProvider: _osmTileProvider,
            ),
            if (polylines.isNotEmpty)
              PolylineLayer(polylines: polylines),
            _buildStartEndMarkers(),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _Legend(
            results: widget.results,
            visibleConfigs: widget.visibleConfigs,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'fit_bounds',
            onPressed: _fitBounds,
            backgroundColor: Colors.white,
            child: const Icon(Icons.fit_screen, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildStartEndMarkers() {
    TrackPoint? first;
    TrackPoint? last;

    for (int i = 0; i < widget.results.length; i++) {
      final visible = i < widget.visibleConfigs.length
          ? widget.visibleConfigs[i]
          : true;
      if (!visible) continue;
      final r = widget.results[i];
      if (r.points.isNotEmpty) {
        first ??= r.points.first;
        last = r.points.last;
        break;
      }
    }

    if (first == null) return const SizedBox.shrink();

    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(first.latitude, first.longitude),
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
          ),
        ),
        if (last != null && last != first)
          Marker(
            point: LatLng(last.latitude, last.longitude),
            width: 28,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final List<FilteredTrackResult> results;
  final List<bool> visibleConfigs;

  const _Legend({required this.results, required this.visibleConfigs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < results.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < visibleConfigs.length && visibleConfigs[i]
                          ? results[i].params.color
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    results[i].params.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: i < visibleConfigs.length && visibleConfigs[i]
                          ? Colors.black87
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
