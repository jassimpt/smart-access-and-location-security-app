import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/text_constants.dart';
import '../constants/map_constants.dart';
import '../models/location_snapshot.dart';
import 'location_marker.dart';
import 'map_attribution.dart';
import 'map_controls.dart';
import 'map_tile_layer.dart';

class LocationMap extends ConsumerStatefulWidget {
  const LocationMap({
    required this.snapshot,
    this.routes = const [],
    this.title = TextConstants.mapTitle,
    this.fitRoute = false,
    super.key,
  });
  final LocationSnapshot snapshot;
  final List<List<LatLng>> routes;
  final String title;
  final bool fitRoute;

  @override
  ConsumerState<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends ConsumerState<LocationMap> {
  final _controller = MapController();
  bool _ready = false;
  bool _hasTileError = false;
  int _tileVersion = 0;

  LatLng get _point =>
      LatLng(widget.snapshot.latitude, widget.snapshot.longitude);

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        (oldWidget.snapshot.latitude != widget.snapshot.latitude ||
            oldWidget.snapshot.longitude != widget.snapshot.longitude)) {
      _controller.move(_point, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Recenters the map on the most recent displayed position.
  void _center() {
    if (_ready) _controller.move(_point, _controller.camera.zoom);
  }

  /// Changes zoom within the supported map range.
  void _zoom(double change) {
    if (!_ready) return;
    _controller.move(
      _controller.camera.center,
      (_controller.camera.zoom + change).clamp(
        MapConstants.minZoom,
        MapConstants.maxZoom,
      ),
    );
  }

  /// Shows one recoverable notice when map imagery cannot be loaded.
  void _onTileError(TileImage tile, Object error, StackTrace? stack) {
    if (_hasTileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasTileError) setState(() => _hasTileError = true);
    });
  }

  /// Recreates failed tiles without discarding the persistent map cache.
  void _retry() => setState(() {
    _hasTileError = false;
    _tileVersion++;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              TextConstants.mapGestureHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).width >= 600 ? 420 : 320,
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _point,
                    initialCameraFit:
                        widget.fitRoute &&
                            widget.routes.expand((route) => route).length > 1
                        ? CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(
                              widget.routes.expand((route) => route).toList(),
                            ),
                            padding: const EdgeInsets.all(48),
                            maxZoom: 17,
                          )
                        : null,
                    initialZoom: widget.snapshot.isApproximate == true
                        ? 12
                        : MapConstants.initialZoom,
                    minZoom: MapConstants.minZoom,
                    maxZoom: MapConstants.maxZoom,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    onMapReady: () => _ready = true,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    MapTileLayer(
                      key: ValueKey(_tileVersion),
                      onTileError: _onTileError,
                    ),
                    if (widget.routes.isNotEmpty)
                      PolylineLayer(
                        polylines: widget.routes
                            .where((route) => route.length > 1)
                            .map(
                              (route) => Polyline(
                                points: route,
                                color: theme.colorScheme.primary,
                                strokeWidth: 4,
                              ),
                            )
                            .toList(),
                      ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _point,
                          radius: widget.snapshot.accuracy,
                          useRadiusInMeter: true,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderColor: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point,
                          width: 36,
                          height: 36,
                          child: const LocationMarker(),
                        ),
                      ],
                    ),
                    MapControls(
                      onCenter: _center,
                      onZoomIn: () => _zoom(1),
                      onZoomOut: () => _zoom(-1),
                    ),
                  ],
                ),
              ),
            ),
            const MapAttribution(),
            Text(
              TextConstants.mapOfflineHint,
              style: theme.textTheme.bodySmall,
            ),
            if (_hasTileError) ...[
              const SizedBox(height: 12),
              Text(
                TextConstants.mapUnavailable,
                style: theme.textTheme.bodySmall,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _retry,
                  child: const Text(TextConstants.retryMap),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
