with open('test/app_test.dart', 'r') as f:
    text = f.read()

text = text.replace('const FarmerProfile(', 'FarmerProfile(')
text = text.replace('const PlotLocation(', 'PlotLocation(')
text = text.replace('status: FarmerStatus.', 'lands: [LandRecord(id: "L1", crop: "Crop", season: "Season", totalAcres: 1, nurseryAcres:0, mainAcres:1, details:"")], status: FarmerStatus.')

text = text.replace('latitude: ', 'polygonPoints: [PlotCoordinate(')
text = text.replace(',\n              longitude: ', ', ')
text = text.replace(',\n              displayAddress: ', ')], displayAddress: ')
text = text.replace(',\n                  longitude: ', ', ')
text = text.replace(',\n                  displayAddress: ', ')], displayAddress: ')

text = text.replace(',\n            longitude: ', ', ')
text = text.replace(',\n            displayAddress: ', ')], displayAddress: ')


with open('test/app_test.dart', 'w') as f:
    f.write(text)
    
print("done")
