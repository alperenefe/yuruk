import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/track_point.dart';

class RunMapWidget extends StatefulWidget {
  final TrackPoint? currentPosition;
  final List<TrackPoint> routePoints;
  final VoidCallback? onRecenter;

  const RunMapWidget({
    super.key,
    this.currentPosition,
    required this.routePoints,
    this.onRecenter,
  });

  @override
  State<RunMapWidget> createState() => _RunMapWidgetState();
}

class _RunMapWidgetState extends State<RunMapWidget> {
  final MapController _mapController = MapController();
  bool _isAutoCenter = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Don't try to move map until it's ready
  }

  @override
  void didUpdateWidget(RunMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (_isAutoCenter && _isMapReady && widget.currentPosition != null) {
      _centerOnCurrentPosition();
    }
  }

  void _centerOnCurrentPosition() {
    if (widget.currentPosition != null && _isMapReady && mounted) {
      try {
        _mapController.move(
          LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          16.0,
        );
      } catch (e) {
        // Ignore if controller not ready yet
      }
    }
  }

  void _onMapEvent(MapEvent event) {
    // Mark map as ready on first event
    if (!_isMapReady) {
      setState(() {
        _isMapReady = true;
      });
      // Center on current position once map is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.currentPosition != null) {
          _centerOnCurrentPosition();
        }
      });
    }
    
    // Disable auto-center if user manually moves map
    if (event is MapEventMoveStart && event.source != MapEventSource.mapController) {
      setState(() {
        _isAutoCenter = false;
      });
    }
  }

  void _onRecenter() {
    setState(() {
      _isAutoCenter = true;
    });
    _centerOnCurrentPosition();
    widget.onRecenter?.call();
  }

  @override
  Widget build(BuildContext context) {
    final routeLatLngs = widget.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.currentPosition != null
                ? LatLng(
                    widget.currentPosition!.latitude,
                    widget.currentPosition!.longitude,
                  )
                : const LatLng(39.9208, 32.8541),
            initialZoom: 14.0,
            onMapEvent: _onMapEvent,
          ),
          children: [
            TileLayer(
              // HTTP kullan (SSL sorunu için geçici çözüm)
              urlTemplate: 'http://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.trendyol.yuruk',
              tileProvider: NetworkTileProvider(),
            ),
            
            if (routeLatLngs.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeLatLngs,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
            
            if (widget.currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.currentPosition!.latitude,
                      widget.currentPosition!.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: widget.currentPosition != null ? _onRecenter : null,
            backgroundColor: Colors.white,
            elevation: _isAutoCenter ? 2 : 6,
            child: Icon(
              _isAutoCenter ? Icons.my_location : Icons.location_searching,
              color: widget.currentPosition == null 
                  ? Colors.grey.withOpacity(0.3)
                  : (_isAutoCenter ? Colors.blue : Colors.orange),
            ),
          ),
        ),
      ],
    );
  }
}
