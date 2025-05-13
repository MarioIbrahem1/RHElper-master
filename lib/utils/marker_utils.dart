import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerUtils {
  // Cache for marker icons to avoid recreating them
  static final Map<String, BitmapDescriptor> _markerIconCache = {};

  /// Creates a custom car marker from an asset image
  static Future<BitmapDescriptor> createCarMarkerFromAsset(
    String assetPath, {
    double width = 80,
    double height = 80,
  }) async {
    // Check if the icon is already in cache
    final cacheKey = '${assetPath}_${width}_$height';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Load the asset image
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width.toInt(),
      targetHeight: height.toInt(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List markerImageBytes = (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!
        .buffer
        .asUint8List();

    final BitmapDescriptor icon = BitmapDescriptor.bytes(markerImageBytes);

    // Cache the icon
    _markerIconCache[cacheKey] = icon;

    return icon;
  }

  /// Creates a custom car marker with a specific color
  static Future<BitmapDescriptor> createColoredCarMarker(
    Color color, {
    double width = 80,
    double height = 80,
  }) async {
    // For now, we'll use the asset image. In a future implementation,
    // we could create a colored car icon programmatically
    return createCarMarkerFromAsset(
      'assets/images/carDark.png',
      width: width,
      height: height,
    );
  }
}
