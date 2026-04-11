import os
import re

# We will apply .tr to the handful of missing hardcoded strings we noticed.
# This is a targeted patch since blindly adding .tr to ALL Text() calls can break variables.

targeted_replacements = [
    ("lib/screens/support_screens.dart", "Text('Summary',", "Text('Summary'.tr,"),
    ("lib/screens/crop_plan_screen.dart", "Text('All Farmers',", "Text('All Farmers'.tr,"),
    ("lib/screens/crop_plan_screen.dart", "Text('Farmer Details',", "Text('Farmer Details'.tr,"),
    ("lib/screens/crop_plan_screen.dart", "Text('Harvest Date Options',", "Text('Harvest Date Options'.tr,"),
    ("lib/screens/crop_plan_screen.dart", "Text('Planned Activities',", "Text('Planned Activities'.tr,"),
    ("lib/screens/home_screen.dart", "Text('Farmer-wise Tracking',", "Text('Farmer-wise Tracking'.tr,"),
    ("lib/screens/misa_ai_screen.dart", "Text('Conversation',", "Text('Conversation'.tr,"),
    ("lib/screens/engagement_screens.dart", "Text('Planned Action',", "Text('Planned Action'.tr,"),
]

for file_path, old, new in targeted_replacements:
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        content = content.replace(old, new)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)

print("Targeted `.tr` replacements added.")
