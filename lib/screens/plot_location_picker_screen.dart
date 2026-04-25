import 'dart:async';
import 'dart:convert';

import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/farmer.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Polygon-mode map picker using Google Maps Flutter.
/// Tap up to 4 corners on the map to define a plot boundary.
/// The polygon is filled and each corner is numbered.
class PlotLocationPickerScreen extends StatefulWidget {
  const PlotLocationPickerScreen({
    super.key,
    required this.initialTarget,
    required this.initialZoom,
    required this.enableMyLocation,
  });

  final LatLng initialTarget;
  final double initialZoom;
  final bool enableMyLocation;

  @override
  State<PlotLocationPickerScreen> createState() =>
      _PlotLocationPickerScreenState();
}

class _PlotLocationPickerScreenState
    extends State<PlotLocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<LatLng> _points = [];
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};

  bool _isConfirming = false;
  bool _isSearching = false;
  String? _searchFeedback;
  List<_Suggestion> _suggestions = const [];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Map tap ─────────────────────────────────────────────────────────────

  void _onMapTap(LatLng latLng) {
    if (_points.length >= 4) return;
    setState(() {
      _points.add(latLng);
      _rebuildOverlays();
    });
  }

  void _resetPolygon() {
    setState(() {
      _points.clear();
      _markers = {};
      _polygons = {};
    });
  }

  void _rebuildOverlays() {
    final markers = <Marker>{};
    for (var i = 0; i < _points.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('pt_$i'),
          position: _points[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _markerHue(i),
          ),
          infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        ),
      );
    }

    final polygons = <Polygon>{};
    if (_points.length >= 3) {
      final ring = [..._points, _points.first];
      polygons.add(
        Polygon(
          polygonId: const PolygonId('plot'),
          points: ring,
          fillColor: AppColors.brandGreen.withAlpha(60),
          strokeColor: AppColors.brandGreen,
          strokeWidth: 2,
        ),
      );
    }

    _markers = markers;
    _polygons = polygons;
  }

  double _markerHue(int index) {
    const hues = [
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueYellow,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueRed,
    ];
    return hues[index % hues.length];
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _isSearching = false;
        _searchFeedback = null;
        _suggestions = const [];
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchFeedback = null;
      _suggestions = const [];
    });
    try {
      // Use OpenStreetMap Nominatim — no API key needed, works on web & mobile.
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'in',
      });
      final response = await http.get(uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'ekutir-agent-app/1.0',
          });

      if (!mounted) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw Exception('bad response');

      final suggestions = decoded
          .whereType<Map<String, dynamic>>()
          .map(_parseSuggestion)
          .whereType<_Suggestion>()
          .toList();

      setState(() {
        _isSearching = false;
        _suggestions = suggestions.take(6).toList();
        _searchFeedback =
            suggestions.isEmpty ? 'No locations found for "$query".' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchFeedback = 'Search unavailable. Move the map manually.';
      });
    }
  }

  _Suggestion? _parseSuggestion(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat'] ?? ''}');
    final lng = double.tryParse('${json['lon'] ?? ''}');
    final name = (json['display_name'] as String?)?.trim();
    if (lat == null || lng == null || name == null || name.isEmpty) return null;
    final parts = name.split(',').map((s) => s.trim()).toList();
    return _Suggestion(
      title: parts.first,
      subtitle: parts.length > 1 ? parts.skip(1).join(', ') : null,
      target: LatLng(lat, lng),
    );
  }

  Future<void> _selectSuggestion(_Suggestion s) async {
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.text = s.title;
      _suggestions = const [];
      _searchFeedback = null;
    });
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(s.target, 17),
    );
  }

  // ─── Confirm ──────────────────────────────────────────────────────────────

  Future<void> _confirmBounds() async {
    if (_points.length < 4) return;
    setState(() => _isConfirming = true);

    String? displayAddress;
    try {
      final center = _centroid(_points);
      // Reverse geocode via Nominatim (no key required).
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '${center.latitude}',
        'lon': '${center.longitude}',
        'format': 'jsonv2',
      });
      final response = await http.get(uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'ekutir-agent-app/1.0',
          });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        displayAddress = data['display_name'] as String?;
      }
    } catch (_) {
      // Fallback: use coordinates string.
    }

    if (!mounted) return;

    final plot = PlotLocation(
      polygonPoints: _points
          .map((p) => PlotCoordinate(p.latitude, p.longitude))
          .toList(),
      displayAddress: displayAddress,
      capturedAt: DateTime.now(),
    );
    Navigator.of(context).pop(plot);
  }

  LatLng _centroid(List<LatLng> pts) {
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canConfirm = _points.length == 4 && !_isConfirming;

    return PageScaffold(
      title: 'Plot Bounds'.tr,
      showBack: true,
      description: 'Tap the map to place 4 corner points. A polygon will be drawn automatically.',
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('confirm_plot_bounds_button'),
          style: filledButtonStyle(),
          onPressed: canConfirm ? _confirmBounds : null,
          icon: _isConfirming
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _isConfirming
                  ? 'Saving...'
                  : _points.length == 4
                      ? 'Confirm Plot Bounds'
                      : 'Tap ${4 - _points.length} more point${4 - _points.length == 1 ? '' : 's'}',
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search Location', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('plot_search_field'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search village or landmark…'.tr,
                    prefixIcon: const Icon(Icons.search, color: AppColors.heroForest, size: 20),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _suggestions = const [];
                                    _searchFeedback = null;
                                  });
                                },
                              )
                            : null,
                  ),
                ),
                if (_searchFeedback != null) ...[
                  const SizedBox(height: 8),
                  Text(_searchFeedback!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                ],
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined, color: AppColors.heroForest),
                          title: Text(s.title),
                          subtitle: s.subtitle != null ? Text(s.subtitle!) : null,
                          trailing: const Icon(Icons.north_west),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Points counter + reset ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_points.length}/4 corners placed',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_points.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetPolygon,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Map ─────────────────────────────────────────────────────────
          SectionCard(
            useInnerPadding: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 440,
                child: kIsWeb
                    ? _WebMapFallback(
                        points: _points,
                        onReset: _resetPolygon,
                      )
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: widget.initialTarget,
                          zoom: widget.initialZoom,
                        ),
                        myLocationEnabled: widget.enableMyLocation,
                        myLocationButtonEnabled: widget.enableMyLocation,
                        markers: _markers,
                        polygons: _polygons,
                        onTap: _onMapTap,
                        onMapCreated: (c) => _mapController = c,
                        mapType: MapType.satellite,
                        zoomControlsEnabled: true,
                        compassEnabled: true,
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Coordinates summary ─────────────────────────────────────────
          if (_points.isNotEmpty)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Captured Points',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ..._points.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              _PointBadge(number: e.key + 1),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${e.value.latitude.toStringAsFixed(6)}, ${e.value.longitude.toStringAsFixed(6)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
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

// ─── Web fallback ─────────────────────────────────────────────────────────────
// google_maps_flutter doesn't work on Flutter Web. Show a clear message
// with the captured coordinates instead.

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback({required this.points, required this.onReset});

  final List<LatLng> points;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 52, color: AppColors.brandGreen),
              const SizedBox(height: 12),
              Text(
                'Map is only available on the Android / iOS app.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'On the native app, tap four corners of the farmer\'s plot to draw a boundary polygon.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('${points.length} point(s) captured',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.brandGreenDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _PointBadge extends StatelessWidget {
  const _PointBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.brandGreen,
      const Color(0xFFF9A825),
      const Color(0xFFEF6C00),
      AppColors.danger,
    ];
    return CircleAvatar(
      radius: 12,
      backgroundColor: colors[(number - 1) % colors.length],
      child: Text(
        '$number',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.title,
    required this.target,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final LatLng target;
}
