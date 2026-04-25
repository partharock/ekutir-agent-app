import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/farmer.dart';
import '../screens/plot_location_picker_screen.dart';

abstract class PlotLocationService {
  const PlotLocationService();

  Future<PlotLocation?> capturePlotLocation(
    BuildContext context, {
    required String locationHint,
    PlotLocation? currentLocation,
  });
}

class PlotLocationException implements Exception {
  const PlotLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GoogleMapsPlotLocationService implements PlotLocationService {
  const GoogleMapsPlotLocationService();

  // Centre of India as fallback starting point
  static const LatLng _defaultTarget = LatLng(20.5937, 78.9629);

  @override
  Future<PlotLocation?> capturePlotLocation(
    BuildContext context, {
    required String locationHint,
    PlotLocation? currentLocation,
  }) async {
    final seed = await _resolveInitialSeed(
      locationHint: locationHint,
      currentLocation: currentLocation,
    );

    if (!context.mounted) return null;

    return Navigator.of(context).push<PlotLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlotLocationPickerScreen(
          initialTarget: seed.target,
          initialZoom: seed.zoom,
        ),
      ),
    );
  }

  Future<_PlotLocationSeed> _resolveInitialSeed({
    required String locationHint,
    PlotLocation? currentLocation,
  }) async {
    // If there's already a captured polygon, zoom to its centre
    if (currentLocation != null && currentLocation.polygonPoints.isNotEmpty) {
      final c = currentLocation.center;
      return _PlotLocationSeed(
        target: LatLng(c.latitude, c.longitude),
        zoom: 17,
      );
    }

    // Try GPS first
    final gpsTarget = await _tryGps();
    if (gpsTarget != null) {
      return _PlotLocationSeed(target: gpsTarget, zoom: 17);
    }

    return const _PlotLocationSeed(target: _defaultTarget, zoom: 5.5);
  }

  Future<LatLng?> _tryGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}

class _PlotLocationSeed {
  const _PlotLocationSeed({required this.target, required this.zoom});
  final LatLng target;
  final double zoom;
}
