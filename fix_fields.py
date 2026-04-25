import os, re

def process_file(path):
    with open(path, 'r') as f:
        text = f.read()

    # Replace plotLocation.latitude / .longitude
    text = re.sub(r'plotLocation\.latitude', r'plotLocation.center.latitude', text)
    text = re.sub(r'plotLocation\.longitude', r'plotLocation.center.longitude', text)
    text = re.sub(r'plotLocation!\.latitude', r'plotLocation!.center.latitude', text)
    text = re.sub(r'plotLocation!\.longitude', r'plotLocation!.center.longitude', text)
    text = re.sub(r'plotLocation\?\.latitude', r'plotLocation?.center.latitude', text)
    text = re.sub(r'plotLocation\?\.longitude', r'plotLocation?.center.longitude', text)
    
    # Replace PlotLocation(...) constructor dynamically
    text = re.sub(
        r'PlotLocation\(\s*latitude:\s*([^,]+),\s*longitude:\s*([^,]+),',
        r'PlotLocation(polygonPoints: [PlotCoordinate(\1, \2)],',
        text
    )

    with open(path, 'w') as f:
        f.write(text)

for root, dirs, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))
print('done')
