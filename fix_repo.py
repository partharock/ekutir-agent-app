import re

with open('lib/state/workflow_repository.dart', 'r') as f:
    text = f.read()

start_str = "Map<String, dynamic> _farmerToJson(FarmerProfile farmer) {"
end_str = "}\n\nList<FarmerProfile> _farmersFromJson(List<dynamic> json) {"
end_idx = text.find(end_str)

new_text = """Map<String, dynamic> _farmerToJson(FarmerProfile farmer) {
  return {
    'id': farmer.id,
    'name': farmer.name,
    'phone': farmer.phone,
    'location': farmer.location,
    'lands': farmer.lands.map(_landRecordToJson).toList(),
    'status': farmer.status.name,
    'stage': farmer.stage.name,
    'supportPreview': farmer.supportPreview,
  };
}

FarmerProfile _farmerFromJson(Map<String, dynamic> json) {
  return FarmerProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    location: json['location'] as String,
    lands: (json['lands'] as List<dynamic>? ?? const [])
        .map((e) => _landRecordFromJson(e as Map<String, dynamic>))
        .toList(),
    status: FarmerStatus.values.byName(json['status'] as String),
    stage: FarmerStage.values.byName(json['stage'] as String),
    supportPreview: Map<String, String>.from(
      json['supportPreview'] as Map<String, dynamic>? ?? const {},
    ),
  );
}

Map<String, dynamic> _landRecordToJson(LandRecord land) {
  return {
    'id': land.id,
    'crop': land.crop,
    'season': land.season,
    'totalAcres': land.totalAcres,
    'nurseryAcres': land.nurseryAcres,
    'mainAcres': land.mainAcres,
    'details': land.details,
    'plotLocation': land.plotLocation == null ? null : _plotLocationToJson(land.plotLocation!),
  };
}

LandRecord _landRecordFromJson(Map<String, dynamic> json) {
  return LandRecord(
    id: json['id'] as String,
    crop: json['crop'] as String,
    season: json['season'] as String,
    totalAcres: (json['totalAcres'] as num).toDouble(),
    nurseryAcres: (json['nurseryAcres'] as num).toDouble(),
    mainAcres: (json['mainAcres'] as num).toDouble(),
    details: json['details'] as String,
    plotLocation: _plotLocationFromJson(json['plotLocation'] as Map<String, dynamic>?),
  );
}

Map<String, dynamic> _plotLocationToJson(PlotLocation location) {
  return {
    'polygonPoints': location.polygonPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    'displayAddress': location.displayAddress,
    'capturedAt': location.capturedAt.toIso8601String(),
  };
}

PlotLocation? _plotLocationFromJson(Map<String, dynamic>? json) {
  if (json == null) {
    return null;
  }
  final pointsRaw = json['polygonPoints'] as List<dynamic>? ?? [];
  return PlotLocation(
    polygonPoints: pointsRaw.map((e) => PlotCoordinate((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble())).toList(),
    displayAddress: json['displayAddress'] as String?,
    capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}"""

with open('lib/state/workflow_repository.dart', 'w') as f:
    f.write(text[:text.find(start_str)] + new_text + "\n" + text[end_idx:])
    
print("done")
