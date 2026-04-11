import os

replacements = [
    ("lib/screens/support_screens.dart", "Text('Support Rules',", "Text('Support Rules'.tr,"),
    ("lib/screens/support_screens.dart", "Text('Farmer Details',", "Text('Farmer Details'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Farmer Details',", "Text('Farmer Details'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Harvesting Details',", "Text('Harvesting Details'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Packaging Details',", "Text('Packaging Details'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Weighing Details',", "Text('Weighing Details'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Quantity Comparison',", "Text('Quantity Comparison'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Price Breakdown',", "Text('Price Breakdown'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Receipt Preview',", "Text('Receipt Preview'.tr,"),
    ("lib/screens/harvest_screens.dart", "Text('Transport Details',", "Text('Transport Details'.tr,"),
]

for file_path, old, new in replacements:
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        content = content.replace(old, new)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)

print("Patching completed.")
