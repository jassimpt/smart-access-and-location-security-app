abstract final class MapConstants {
  static const tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const userAgent = 'com.example.smart_access';
  static const attributionUrl = 'https://www.openstreetmap.org/copyright';
  static const initialZoom = 15.0;
  static const minZoom = 3.0;
  static const maxZoom = 18.0;
  static const maxCacheBytes = 100 * 1024 * 1024;
}
