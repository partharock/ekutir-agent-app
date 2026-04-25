import re

with open('test/app_test.dart', 'r') as f:
    text = f.read()

# Replace FarmerProfile fields
text = re.sub(
    r'plotLocation:\s*PlotLocation\(\s*latitude:\s*([^,]+),\s*longitude:\s*([^,]+),\s*displayAddress:\s*([^,]+),\s*capturedAt:\s*([^,\)]+),\s*\),',
    r'',
    text
)

text = re.sub(r'totalLandAcres:\s*[^,]+,', '', text)
text = re.sub(r'crop:\s*[^,]+,', '', text)
text = re.sub(r'season:\s*[^,]+,', '', text)
text = re.sub(r'nurseryLandAcres:\s*[^,]+,', '', text)
text = re.sub(r'mainLandAcres:\s*[^,]+,', '', text)
text = re.sub(r'landDetails:\s*[^,]+,', '', text)

text = re.sub(
    r'status:\s*FarmerStatus',
    r'lands: const [], status: FarmerStatus',
    text
)

def fix_plot_locations_in_test(code):
    return re.sub(
        r'PlotLocation\(\s*latitude:\s*([^,]+),\s*longitude:\s*([^,]+),\s*displayAddress:\s*([^,]+),\s*capturedAt:\s*([^,\)]+),?\s*\)',
        r'PlotLocation(polygonPoints: [PlotCoordinate(\1, \2)], displayAddress: \3, capturedAt: \4)',
        code
    )

text = fix_plot_locations_in_test(text)

with open('test/app_test.dart', 'w') as f:
    f.write(text)

print("done")
