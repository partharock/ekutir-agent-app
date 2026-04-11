import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mappls_gl/mappls_gl.dart';

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

class MapplsPlotLocationService implements PlotLocationService {
  const MapplsPlotLocationService();

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
    if (!context.mounted) {
      return null;
    }

    return Navigator.of(context).push<PlotLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PlotLocationPickerScreen(
          initialTarget: seed.target,
          initialZoom: seed.zoom,
          enableMyLocation: seed.enableMyLocation,
        ),
      ),
    );
  }

  Future<_PlotLocationSeed> _resolveInitialSeed({
    required String locationHint,
    PlotLocation? currentLocation,
  }) async {
    if (currentLocation != null) {
      return _PlotLocationSeed(
        target: LatLng(currentLocation.latitude, currentLocation.longitude),
        zoom: 17,
        enableMyLocation: false,
      );
    }

    final currentTarget = await _tryCurrentLocation();
    if (currentTarget != null) {
      return _PlotLocationSeed(
        target: currentTarget,
        zoom: 17,
        enableMyLocation: true,
      );
    }

    final geocodedTarget = await _tryGeocode(locationHint);
    if (geocodedTarget != null) {
      return _PlotLocationSeed(
        target: geocodedTarget,
        zoom: 15,
        enableMyLocation: false,
      );
    }

    return const _PlotLocationSeed(
      target: _defaultTarget,
      zoom: 5.5,
      enableMyLocation: false,
    );
  }

  Future<LatLng?> _tryCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> _tryGeocode(String locationHint) async {
    final normalizedHint = locationHint.trim();
    if (normalizedHint.isEmpty) {
      return null;
    }

    try {
      final response = await MapplsGeoCoding(
        address: normalizedHint,
      ).callGeocoding();
      final results = response?.results;
      if (results == null || results.isEmpty) {
        return null;
      }
      final first = results.first;
      if (first.latitude == null || first.longitude == null) {
        return null;
      }
      return LatLng(first.latitude!, first.longitude!);
    } catch (_) {
      return null;
    }
  }
}

class _PlotLocationSeed {
  const _PlotLocationSeed({
    required this.target,
    required this.zoom,
    required this.enableMyLocation,
  });

  final LatLng target;
  final double zoom;
  final bool enableMyLocation;
}
