import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mappls_gl/mappls_gl.dart';

import '../models/farmer.dart';
import '../theme/app_colors.dart';
import '../utils/mappls_web.dart';
import '../widgets/common.dart';

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

class _PlotLocationPickerScreenState extends State<PlotLocationPickerScreen> {
  MapplsMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  late LatLng _selectedTarget;
  Timer? _searchDebounce;
  String? _mapErrorMessage;
  String? _searchFeedbackMessage;
  bool _isConfirming = false;
  bool _isSearching = false;
  List<_PlotSearchSuggestion> _searchSuggestions = const [];

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialTarget;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _syncSelectionWithCamera() {
    final target = _mapController?.cameraPosition?.target;
    if (target == null) {
      return;
    }
    setState(() {
      _selectedTarget = target;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    setState(() {});
    final minimumChars = kIsWeb ? 3 : 2;
    if (query.length < minimumChars) {
      setState(() {
        _isSearching = false;
        _searchFeedbackMessage = query.isEmpty
            ? null
            : 'Enter at least $minimumChars characters to search.';
        _searchSuggestions = const [];
      });
      return;
    }
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchFeedbackMessage = null;
        _searchSuggestions = const [];
      });
      return;
    }

    _searchDebounce = Timer(
      Duration(milliseconds: kIsWeb ? 650 : 350),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
      _searchFeedbackMessage = null;
      _searchSuggestions = const [];
    });

    try {
      late List<_PlotSearchSuggestion> suggestions;
      if (kIsWeb) {
        suggestions = await _runWebSearch(query);
      } else {
        final searchCenter =
            _mapController?.cameraPosition?.target ?? _selectedTarget;
        final autoSuggestResponse = await MapplsAutoSuggest(
          query: query,
          location: searchCenter,
          tokenizeAddress: true,
        ).callAutoSuggest();

        suggestions = _suggestionsFromAutoSuggest(
          autoSuggestResponse?.suggestedLocations ?? const [],
        );

        if (suggestions.isEmpty) {
          final geocodeResponse = await MapplsGeoCoding(
            address: query,
          ).callGeocoding();
          suggestions = _suggestionsFromGeocode(
            geocodeResponse?.results ?? const [],
          );
        }
      }

      if (!mounted || _searchController.text.trim() != query) {
        return;
      }

      setState(() {
        _isSearching = false;
        _searchSuggestions = suggestions.take(6).toList(growable: false);
        _searchFeedbackMessage = _searchSuggestions.isEmpty
            ? 'No locations found for "$query".'
            : null;
      });
    } catch (_) {
      if (!mounted || _searchController.text.trim() != query) {
        return;
      }

      setState(() {
        _isSearching = false;
        _searchSuggestions = const [];
        _searchFeedbackMessage =
            'Search is unavailable right now. Try moving the map manually.';
      });
    }
  }

  Future<List<_PlotSearchSuggestion>> _runWebSearch(String query) async {
    final response = await http.get(
      Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'in',
        'addressdetails': '0',
      }),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Web search failed with ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_suggestionFromWebResult)
        .whereType<_PlotSearchSuggestion>()
        .toList(growable: false);
  }

  List<_PlotSearchSuggestion> _suggestionsFromAutoSuggest(
    List<ELocation> results,
  ) {
    return results
        .map(_suggestionFromAutoSuggestLocation)
        .whereType<_PlotSearchSuggestion>()
        .toList(growable: false);
  }

  List<_PlotSearchSuggestion> _suggestionsFromGeocode(
    List<GeoCodeResult> results,
  ) {
    return results
        .map(_suggestionFromGeocodeResult)
        .whereType<_PlotSearchSuggestion>()
        .toList(growable: false);
  }

  _PlotSearchSuggestion? _suggestionFromAutoSuggestLocation(
    ELocation location,
  ) {
    final coordinates = _coordinatesFromAutoSuggestLocation(location);
    final title = _normalizeAddress(location.placeName) ??
        _normalizeAddress(location.alternateName) ??
        _normalizeAddress(location.placeAddress);
    final subtitle = _normalizeAddress(location.placeAddress);

    if (title == null) {
      return null;
    }

    return _PlotSearchSuggestion(
      title: title,
      subtitle: subtitle == title ? null : subtitle,
      target: coordinates,
      mapplsPin: _normalizeAddress(location.mapplsPin),
    );
  }

  _PlotSearchSuggestion? _suggestionFromGeocodeResult(GeoCodeResult result) {
    final latitude = result.latitude;
    final longitude = result.longitude;
    final title = _normalizeAddress(result.poi) ??
        _normalizeAddress(result.houseName) ??
        _normalizeAddress(result.formattedAddress);

    if (title == null || latitude == null || longitude == null) {
      return null;
    }

    return _PlotSearchSuggestion(
      title: title,
      subtitle: _normalizeAddress(result.formattedAddress) == title
          ? null
          : _normalizeAddress(result.formattedAddress),
      target: LatLng(latitude, longitude),
      mapplsPin: _normalizeAddress(result.mapplsPin),
    );
  }

  _PlotSearchSuggestion? _suggestionFromWebResult(Map<String, dynamic> result) {
    final latitude = double.tryParse('${result['lat'] ?? ''}');
    final longitude = double.tryParse('${result['lon'] ?? ''}');
    final displayName = _normalizeAddress(result['display_name'] as String?);

    if (latitude == null || longitude == null || displayName == null) {
      return null;
    }

    final parts = displayName
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final title = parts.isEmpty ? displayName : parts.first;
    final subtitle = parts.length <= 1 ? null : parts.skip(1).join(', ');

    return _PlotSearchSuggestion(
      title: title,
      subtitle: subtitle,
      target: LatLng(latitude, longitude),
    );
  }

  LatLng? _coordinatesFromAutoSuggestLocation(ELocation location) {
    if (location.latitude != null && location.longitude != null) {
      return LatLng(location.latitude!, location.longitude!);
    }
    if (location.entryLatitude != null && location.entryLongitude != null) {
      return LatLng(location.entryLatitude!, location.entryLongitude!);
    }
    return null;
  }

  Future<void> _selectSearchSuggestion(_PlotSearchSuggestion suggestion) async {
    try {
      LatLng? target = suggestion.target;
      if (!kIsWeb && target == null && suggestion.mapplsPin != null) {
        final response = await MapplsPlaceDetail(
          mapplsPin: suggestion.mapplsPin!,
        ).callPlaceDetail();
        if (response?.latitude != null && response?.longitude != null) {
          target = LatLng(response!.latitude!, response.longitude!);
        }
      }

      if (target == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searchFeedbackMessage =
              'That result could not be centered on the map. Try another result.';
        });
        return;
      }

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 17),
        duration: const Duration(milliseconds: 600),
      );

      if (!mounted) {
        return;
      }

      FocusScope.of(context).unfocus();
      final resolvedTarget = target;
      setState(() {
        _selectedTarget = resolvedTarget;
        _searchController.text = suggestion.title;
        _searchSuggestions = const [];
        _searchFeedbackMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchFeedbackMessage =
            'Unable to move to that location right now. Try again.';
      });
    }
  }

  Future<void> _confirmSelection() async {
    setState(() {
      _isConfirming = true;
    });

    String? displayAddress;
    try {
      final response = await MapplsReverseGeocode(
        location: _selectedTarget,
      ).callReverseGeocode();
      final results = response?.results;
      if (results != null && results.isNotEmpty) {
        displayAddress = results.first.formattedAddress;
      }
    } catch (_) {
      // Saving raw coordinates is still useful if reverse geocoding fails.
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      PlotLocation(
        latitude: _selectedTarget.latitude,
        longitude: _selectedTarget.longitude,
        displayAddress: _normalizeAddress(displayAddress),
        capturedAt: DateTime.now(),
      ),
    );
  }

  String? _normalizeAddress(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final mapUnavailableOnWeb = kIsWeb && !isMapplsWebSdkLoaded;
    final searchDisabled = mapUnavailableOnWeb || _mapErrorMessage != null;

    return PageScaffold(
      title: 'Plot GPS Location',
      showBack: true,
      description:
          'Search a nearby place or move the map until the center pin sits on the farmer plot.',
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('confirm_plot_location_button'),
          style: filledButtonStyle(),
          onPressed: _isConfirming || _mapErrorMessage != null
              ? null
              : _confirmSelection,
          icon: _isConfirming
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _isConfirming ? 'Saving Plot Location...' : 'Use This Plot',
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Nearby',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Search by village, landmark, or address to jump the map closer to the plot.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Web search is optimized for finding nearby localities and landmarks before you fine-tune the plot pin.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  key: const Key('plot_location_search_field'),
                  controller: _searchController,
                  enabled: !searchDisabled,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: _runSearch,
                  decoration: InputDecoration(
                    hintText: 'Search village, landmark, or address',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.heroForest,
                    ),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchDebounce?.cancel();
                                  _searchController.clear();
                                  setState(() {
                                    _searchFeedbackMessage = null;
                                    _searchSuggestions = const [];
                                  });
                                },
                                icon: const Icon(Icons.close),
                              )),
                    fillColor: const Color(0xFFF4F5F8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                if (_searchFeedbackMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _searchFeedbackMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (_searchSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchSuggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          key: Key('plot_location_search_result_$index'),
                          leading: const Icon(
                            Icons.place_outlined,
                            color: AppColors.heroForest,
                          ),
                          title: Text(suggestion.title),
                          subtitle: suggestion.subtitle == null
                              ? null
                              : Text(suggestion.subtitle!),
                          trailing: const Icon(Icons.north_west),
                          onTap: () => _selectSearchSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Center Pin',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pan and zoom the map. The green pin stays fixed at the center and marks the saved plot point.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            useInnerPadding: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 420,
                child: mapUnavailableOnWeb
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Mappls web SDK is not configured. Add your web static key in web/mappls-config.js, rebuild the app, and try again.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          MapplsMap(
                            initialCameraPosition: CameraPosition(
                              target: widget.initialTarget,
                              zoom: widget.initialZoom,
                            ),
                            trackCameraPosition: true,
                            myLocationEnabled: widget.enableMyLocation,
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _syncSelectionWithCamera();
                            },
                            onMapError: (code, message) {
                              setState(() {
                                _mapErrorMessage = message;
                              });
                            },
                            onCameraIdle: _syncSelectionWithCamera,
                          ),
                          const IgnorePointer(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 28),
                                child: Icon(
                                  Icons.location_on,
                                  size: 44,
                                  color: AppColors.brandGreen,
                                ),
                              ),
                            ),
                          ),
                          if (_mapErrorMessage != null)
                            Positioned(
                              left: 12,
                              right: 12,
                              top: 12,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDECEC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFF4B4B4),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Map unavailable. Confirm the Mappls app credentials for this platform and try again.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Coordinates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                InfoPair(
                  label: 'Latitude',
                  value: _selectedTarget.latitude.toStringAsFixed(6),
                ),
                const SizedBox(height: 10),
                InfoPair(
                  label: 'Longitude',
                  value: _selectedTarget.longitude.toStringAsFixed(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlotSearchSuggestion {
  const _PlotSearchSuggestion({
    required this.title,
    this.subtitle,
    this.target,
    this.mapplsPin,
  });

  final String title;
  final String? subtitle;
  final LatLng? target;
  final String? mapplsPin;
}
