with open('lib/screens/plot_location_picker_screen.dart', 'r') as f:
    text = f.read()

start_str = "class _PlotLocationPickerScreenState extends State<PlotLocationPickerScreen> {"
end_str = "class _SearchSuggestionTile extends StatelessWidget {"

if start_str in text and end_str in text:
    start_idx = text.find(start_str)
    end_idx = text.find(end_str)

    new_state = """class _PlotLocationPickerScreenState extends State<PlotLocationPickerScreen> {
  MapplsMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  Timer? _searchDebounce;
  String? _mapErrorMessage;
  String? _searchFeedbackMessage;
  bool _isConfirming = false;
  bool _isSearching = false;
  List<_PlotSearchSuggestion> _searchSuggestions = const [];

  final List<LatLng> _polygonPoints = [];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapClick(Point<double> point, LatLng coordinates) {
    if (_polygonPoints.length >= 4) return;
    setState(() {
      _polygonPoints.add(coordinates);
    });
    _drawPolygon();
  }

  void _drawPolygon() async {
    final controller = _mapController;
    if (controller == null) return;
    
    await controller.clearSymbols();
    await controller.clearFills();
    
    for (int i = 0; i < _polygonPoints.length; i++) {
       await controller.addSymbol(
         SymbolOptions(
           geometry: _polygonPoints[i],
           iconImage: 'marker',
           iconSize: 0.5,
           textField: '${i + 1}',
           textOffset: const Offset(0, -2.5),
           textColor: '#FFFFFF',
         ),
       );
    }

    if (_polygonPoints.length == 4) {
      final fillPoints = List<LatLng>.from(_polygonPoints)..add(_polygonPoints.first);
      await controller.addFill(
        FillOptions(
          geometry: [fillPoints],
          fillColor: '#4CAF50',
          fillOpacity: 0.4,
          fillOutlineColor: '#2E7D32',
        )
      );
    }
  }

  void _resetPolygon() {
    setState(() {
      _polygonPoints.clear();
    });
    _drawPolygon();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    setState(() {});
    final minimumChars = kIsWeb ? 3 : 2;
    if (query.length < minimumChars) {
      setState(() {
        _isSearching = false;
        _searchFeedbackMessage = query.isEmpty ? null : 'Enter at least $minimumChars characters to search.';
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
    if (query.isEmpty) return;

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
        final searchCenter = _mapController?.cameraPosition?.target ?? widget.initialTarget;
        final autoSuggestResponse = await MapplsAutoSuggest(
          query: query, location: searchCenter, tokenizeAddress: true,
        ).callAutoSuggest();
        suggestions = _suggestionsFromAutoSuggest(autoSuggestResponse?.suggestedLocations ?? const []);
        if (suggestions.isEmpty) {
          final geocodeResponse = await MapplsGeoCoding(address: query).callGeocoding();
          suggestions = _suggestionsFromGeocode(geocodeResponse?.results ?? const []);
        }
      }

      if (!mounted || _searchController.text.trim() != query) return;

      setState(() {
        _isSearching = false;
        _searchSuggestions = suggestions.take(6).toList(growable: false);
        _searchFeedbackMessage = _searchSuggestions.isEmpty ? 'No locations found for "$query".' : null;
      });
    } catch (_) {
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _isSearching = false;
        _searchFeedbackMessage = 'Unable to search for locations.';
      });
    }
  }

  Future<List<_PlotSearchSuggestion>> _runWebSearch(String query) async {
    final proxyUrl = Uri.parse('/api/mappls/autosuggest?query=${Uri.encodeComponent(query)}');
    final response = await http.get(proxyUrl);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['suggestedLocations'] as List<dynamic>? ?? [];
      return results.map((e) => _PlotSearchSuggestion.fromJson(e)).toList();
    }
    return const [];
  }

  List<_PlotSearchSuggestion> _suggestionsFromAutoSuggest(List<AutoSuggestLocation> data) =>
      data.map((e) => _PlotSearchSuggestion(
            mapplsPin: _normalizeAddress(e.mapplsPin),
            placeName: _normalizeAddress(e.placeName),
            placeAddress: _normalizeAddress(e.placeAddress),
          )).toList();

  List<_PlotSearchSuggestion> _suggestionsFromGeocode(List<GeocodeResults> data) =>
      data.map((e) => _PlotSearchSuggestion(
            mapplsPin: _normalizeAddress(e.mapplsPin),
            placeName: _normalizeAddress(e.formattedAddress),
            placeAddress: '',
          )).toList();

  String? _normalizeAddress(String? val) {
    if (val == null) return null;
    final s = val.trim();
    if (s.isEmpty || s.toLowerCase() == 'a') return null;
    return s;
  }

  Future<void> _selectSuggestion(_PlotSearchSuggestion suggestion) async {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.text = suggestion.placeName ?? suggestion.mapplsPin ?? '';
      _searchSuggestions = const [];
      _searchFeedbackMessage = null;
    });
    FocusScope.of(context).unfocus();

    try {
      LatLng? target;
      if (!kIsWeb && suggestion.mapplsPin != null) {
        final response = await MapplsPlaceDetail(mapplsPin: suggestion.mapplsPin!).callPlaceDetail();
        final lat = response?.latitude;
        final lng = response?.longitude;
        if (lat != null && lng != null) target = LatLng(lat, lng);
      }
      
      if (target != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
        );
      }
    } catch (_) { }
  }

  Future<void> _confirmLocation() async {
    if (_polygonPoints.length < 4) return;
    
    setState(() => _isConfirming = true);

    try {
      String? displayAddress;
      if (!kIsWeb) {
        final center = PlotLocation(polygonPoints: _polygonPoints.map((p) => PlotCoordinate(p.latitude, p.longitude)).toList(), capturedAt: DateTime.now()).center;
        final response = await MapplsReverseGeocode(location: LatLng(center.latitude, center.longitude)).callReverseGeocoding();
        final results = response?.results ?? const [];
        if (results.isNotEmpty) {
          final best = results.first;
          displayAddress = best.formattedAddress;
        }
      }
      
      if (!mounted) return;

      final plot = PlotLocation(
        polygonPoints: _polygonPoints.map((p) => PlotCoordinate(p.latitude, p.longitude)).toList(),
        displayAddress: displayAddress ?? 'Unknown Location',
        capturedAt: DateTime.now(),
      );

      Navigator.of(context).pop(plot);
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        showMockSnackBar(context, 'Unable to confirm plot: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapUnavailableOnWeb = kIsWeb && !isMapplsWebSdkLoaded;

    return PageScaffold(
      title: 'Plot Location'.tr,
      showBack: true,
      description: 'Find the land boundary. Tap 4 corners of your plot.',
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('confirm_plot_bounds_button'),
          style: filledButtonStyle(),
          onPressed: _polygonPoints.length == 4 && !_isConfirming ? _confirmLocation : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _isConfirming
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Confirm Bounds'.tr),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('plot_search_field'),
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search village or landmark...'.tr,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
            ),
          ),
          if (_searchFeedbackMessage != null || _searchSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchFeedbackMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _searchFeedbackMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      )
                    else
                      ..._searchSuggestions.map((suggestion) {
                        return _SearchSuggestionTile(
                          suggestion: suggestion,
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Map (${_polygonPoints.length}/4 points)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_polygonPoints.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetPolygon,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                )
            ],
          ),
          const SizedBox(height: 8),
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
                            'Mappls web SDK is not configured. Add your web static key in web/mappls-config.js.',
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
                            trackCameraPosition: false,
                            myLocationEnabled: widget.enableMyLocation,
                            onMapClick: _onMapClick,
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            onMapError: (code, message) {
                              setState(() {
                                _mapErrorMessage = message;
                              });
                            },
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
                                  border: Border.all(color: AppColors.danger),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: AppColors.danger),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _mapErrorMessage!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.danger,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

"""
    with open('lib/screens/plot_location_picker_screen.dart', 'w') as f:
        f.write(text[:start_idx] + new_state + text[end_idx:])
        
print("done")
