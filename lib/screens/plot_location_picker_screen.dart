import 'dart:async';
import 'dart:convert';

import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/farmer.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Polygon-mode plot picker using flutter_map + ESRI World Imagery satellite tiles.
/// No API key required. Tap up to 4 corners to define the plot boundary.
class PlotLocationPickerScreen extends StatefulWidget {
  const PlotLocationPickerScreen({
    super.key,
    required this.initialTarget,
    required this.initialZoom,
  });

  final LatLng initialTarget;
  final double initialZoom;

  @override
  State<PlotLocationPickerScreen> createState() =>
      _PlotLocationPickerScreenState();
}

class _PlotLocationPickerScreenState extends State<PlotLocationPickerScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<LatLng> _points = [];
  bool _isConfirming = false;
  bool _isSearching = false;
  String? _searchFeedback;
  List<_Suggestion> _suggestions = const [];

  // ESRI World Imagery tile URL — free, no API key needed
  static const String _esriTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ─── Map tap ─────────────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng latLng) {
    if (_points.length >= 4) return;
    setState(() => _points.add(latLng));
  }

  void _resetPolygon() => setState(() => _points.clear());

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() => _points.removeLast());
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
    _searchDebounce =
        Timer(const Duration(milliseconds: 500), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchFeedback = null;
      _suggestions = const [];
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'in',
      });
      final response = await http.get(uri, headers: const {
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

  void _selectSuggestion(_Suggestion s) {
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.text = s.title;
      _suggestions = const [];
      _searchFeedback = null;
    });
    _mapController.move(s.target, 17);
  }

  // ─── Confirm ──────────────────────────────────────────────────────────────

  Future<void> _confirmBounds() async {
    if (_points.length < 4) return;
    setState(() => _isConfirming = true);

    String? displayAddress;
    try {
      final center = _centroid(_points);
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '${center.latitude}',
        'lon': '${center.longitude}',
        'format': 'jsonv2',
      });
      final response = await http.get(uri, headers: const {
        'Accept': 'application/json',
        'User-Agent': 'ekutir-agent-app/1.0',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        displayAddress = data['display_name'] as String?;
      }
    } catch (_) {
      // Use coordinates as fallback
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
    final lng =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canConfirm = _points.length == 4 && !_isConfirming;
    final remaining = 4 - _points.length;

    return PageScaffold(
      title: 'Plot Bounds'.tr,
      showBack: true,
      description:
          'Tap the map to place 4 corner points. A polygon will be drawn automatically.',
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
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _isConfirming
                  ? 'Saving...'
                  : _points.length == 4
                      ? 'Confirm Plot Bounds'
                      : 'Tap $remaining more point${remaining == 1 ? '' : 's'}',
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
                Text('Search Location',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('plot_search_field'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search village or landmark…'.tr,
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.heroForest, size: 20),
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
                  Text(
                    _searchFeedback!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
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
                          leading: const Icon(Icons.place_outlined,
                              color: AppColors.heroForest),
                          title: Text(s.title),
                          subtitle:
                              s.subtitle != null ? Text(s.subtitle!) : null,
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

          // ── Points counter + actions ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_points.length}/4 corners placed',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  if (_points.isNotEmpty)
                    TextButton.icon(
                      onPressed: _undoLastPoint,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Undo'),
                    ),
                  if (_points.length > 1)
                    TextButton.icon(
                      onPressed: _resetPolygon,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset'),
                    ),
                ],
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
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.initialTarget,
                    initialZoom: widget.initialZoom,
                    maxZoom: 20,
                    onTap: _onMapTap,
                  ),
                  children: [
                    // Satellite imagery layer (ESRI — no key required)
                    TileLayer(
                      urlTemplate: _esriTileUrl,
                      userAgentPackageName: 'com.ekutir.agent_app',
                      maxZoom: 20,
                      maxNativeZoom: 19,
                    ),
                    // Filled polygon (shows after 3 points)
                    if (_points.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [..._points, _points.first],
                            color: AppColors.brandGreen.withValues(alpha: 0.25),
                            borderColor: AppColors.brandGreen,
                            borderStrokeWidth: 2.5,
                          ),
                        ],
                      ),
                    // Polyline connecting points in order
                    if (_points.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _points,
                            color: AppColors.brandGreen,
                            strokeWidth: 2,
                          ),
                        ],
                      ),
                    // Corner markers
                    MarkerLayer(
                      markers: _points.asMap().entries.map((e) {
                        final color = _markerColor(e.key);
                        return Marker(
                          point: e.value,
                          width: 36,
                          height: 36,
                          child: _CornerMarker(
                            number: e.key + 1,
                            color: color,
                          ),
                        );
                      }).toList(),
                    ),
                    // Attribution (required by ESRI ToS)
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('Esri World Imagery'),
                        TextSourceAttribution('© OpenStreetMap contributors',
                            onTap: null),
                      ],
                    ),
                  ],
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
                              _PointBadge(
                                  number: e.key + 1,
                                  color: _markerColor(e.key)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${e.value.latitude.toStringAsFixed(6)}, '
                                  '${e.value.longitude.toStringAsFixed(6)}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
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

  Color _markerColor(int index) {
    const colors = [
      AppColors.brandGreen,
      Color(0xFFF9A825),
      Color(0xFFEF6C00),
      AppColors.danger,
    ];
    return colors[index % colors.length];
  }
}

// ─── Corner Marker Widget ─────────────────────────────────────────────────────

class _CornerMarker extends StatelessWidget {
  const _CornerMarker({required this.number, required this.color});
  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Point Badge ──────────────────────────────────────────────────────────────

class _PointBadge extends StatelessWidget {
  const _PointBadge({required this.number, required this.color});
  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: color,
      child: Text(
        '$number',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Suggestion model ─────────────────────────────────────────────────────────

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
