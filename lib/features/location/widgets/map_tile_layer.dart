import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/map_constants.dart';

final mapTileProviderFactoryProvider = Provider<TileProvider Function()>(
  (ref) =>
      () => NetworkTileProvider(
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: MapConstants.maxCacheBytes,
        ),
        attemptDecodeOfHttpErrorResponses: false,
      ),
);

class MapTileLayer extends ConsumerStatefulWidget {
  const MapTileLayer({required this.onTileError, super.key});
  final void Function(TileImage, Object, StackTrace?) onTileError;

  @override
  ConsumerState<MapTileLayer> createState() => _MapTileLayerState();
}

class _MapTileLayerState extends ConsumerState<MapTileLayer> {
  late final TileProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ref.read(mapTileProviderFactoryProvider)();
  }

  @override
  Widget build(BuildContext context) => TileLayer(
    urlTemplate: MapConstants.tileUrl,
    userAgentPackageName: MapConstants.userAgent,
    tileProvider: _provider,
    maxNativeZoom: 19,
    panBuffer: 0,
    errorTileCallback: widget.onTileError,
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
  );
}
