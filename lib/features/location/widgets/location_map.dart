import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/text_constants.dart';
import '../constants/map_constants.dart';
import '../models/location_snapshot.dart';
import '../models/map_boundary.dart';
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
    this.boundaryRadius,
    this.onPointSelected,
    this.showPositionMarker = true,
    this.markerLabel = TextConstants.mapMarker,
    this.gestureHint = TextConstants.mapGestureHint,
    this.initialZoom,
    this.height,
    this.boundaries = const [],
    super.key,
  });
  final LocationSnapshot snapshot;
  final List<List<LatLng>> routes;
  final String title;
  final bool fitRoute;
  final double? boundaryRadius;
  final ValueChanged<LatLng>? onPointSelected;
  final bool showPositionMarker;
  final String markerLabel;
  final String gestureHint;
  final double? initialZoom;
  final double? height;
  final List<MapBoundary> boundaries;

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
        widget.boundaries.isNotEmpty &&
        (oldWidget.boundaries.length != widget.boundaries.length ||
            oldWidget.boundaries.indexed.any(
              (entry) =>
                  entry.$2.center != widget.boundaries[entry.$1].center ||
                  entry.$2.radius != widget.boundaries[entry.$1].radius,
            ))) {
      _controller.fitCamera(_areasFit());
    } else if (_ready &&
        widget.boundaryRadius != null &&
        oldWidget.boundaryRadius != widget.boundaryRadius) {
      _controller.fitCamera(_boundaryFit());
    } else if (_ready &&
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

  /// Fits the selected boundary while keeping its radius visible.
  CameraFit _boundaryFit() {
    const distance = Distance();
    final diagonal = widget.boundaryRadius! * 1.42;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints([
        distance.offset(_point, diagonal, 45),
        distance.offset(_point, diagonal, 225),
      ]),
      padding: const EdgeInsets.all(32),
      maxZoom: MapConstants.maxZoom,
    );
  }

  /// Fits all saved boundaries in the overview map.
  CameraFit _areasFit() {
    const distance = Distance();
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints([
        for (final boundary in widget.boundaries) ...[
          distance.offset(boundary.center, boundary.radius * 1.42, 45),
          distance.offset(boundary.center, boundary.radius * 1.42, 225),
        ],
      ]),
      padding: const EdgeInsets.all(40),
      maxZoom: 16,
    );
  }

  /// Recenters the map on the most recent displayed position.
  void _center() {
    if (!_ready) return;
    if (widget.boundaries.isNotEmpty) {
      _controller.fitCamera(_areasFit());
    } else if (widget.boundaryRadius != null) {
      _controller.fitCamera(_boundaryFit());
    } else {
      _controller.move(_point, _controller.camera.zoom);
    }
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                widget.height ??
                (MediaQuery.sizeOf(context).height * .38).clamp(260.0, 480.0),
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _point,
                initialCameraFit: widget.boundaries.isNotEmpty
                    ? _areasFit()
                    : widget.fitRoute &&
                          widget.routes.expand((route) => route).length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(
                          widget.routes.expand((route) => route).toList(),
                        ),
                        padding: const EdgeInsets.all(48),
                        maxZoom: 17,
                      )
                    : widget.boundaryRadius != null
                    ? _boundaryFit()
                    : null,
                onTap: widget.onPointSelected == null
                    ? null
                    : (tap, point) => widget.onPointSelected!(point),
                initialZoom:
                    widget.initialZoom ??
                    (widget.snapshot.isApproximate == true
                        ? 12
                        : MapConstants.initialZoom),
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
                if (widget.boundaries.isNotEmpty)
                  CircleLayer(
                    circles: [
                      for (final boundary in widget.boundaries)
                        CircleMarker(
                          point: boundary.center,
                          radius: boundary.radius,
                          useRadiusInMeter: true,
                          color: theme.colorScheme.primary.withValues(
                            alpha: .12,
                          ),
                          borderColor: theme.colorScheme.primary.withValues(
                            alpha: .65,
                          ),
                          borderStrokeWidth: 2,
                        ),
                    ],
                  ),
                if (widget.boundaries.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      for (final boundary in widget.boundaries)
                        Marker(
                          point: boundary.center,
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: boundary.label,
                            child: LocationMarker(label: boundary.label),
                          ),
                        ),
                    ],
                  ),
                if (widget.showPositionMarker || widget.boundaryRadius != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _point,
                        radius:
                            widget.boundaryRadius ?? widget.snapshot.accuracy,
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
                if (widget.showPositionMarker)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _point,
                        width: 36,
                        height: 36,
                        child: LocationMarker(label: widget.markerLabel),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.onPointSelected != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.gestureHint,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                Row(
                  children: [
                    Tooltip(
                      message:
                          '${widget.gestureHint}\n${TextConstants.mapOfflineHint}',
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: MapAttribution()),
                  ],
                ),
              ],
            ),
          ),
          if (_hasTileError)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextConstants.mapUnavailable,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    TextConstants.mapOfflineHint,
                    style: theme.textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: _retry,
                    child: const Text(TextConstants.retryMap),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
