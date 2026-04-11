import os

replacements = [
    # models/crop_plan.dart
    ("lib/models/crop_plan.dart", "return 'Planned';", "return 'Planned'.tr;"),
    ("lib/models/crop_plan.dart", "return 'In Progress';", "return 'In Progress'.tr;"),
    ("lib/models/crop_plan.dart", "return 'Completed';", "return 'Completed'.tr;"),
    
    # models/farmer.dart
    ("lib/models/farmer.dart", "return 'Willing';", "return 'Willing'.tr;"),
    ("lib/models/farmer.dart", "return 'Booked';", "return 'Booked'.tr;"),
    ("lib/models/farmer.dart", "return 'Nursery';", "return 'Nursery'.tr;"),
    ("lib/models/farmer.dart", "return 'Growth';", "return 'Growth'.tr;"),
    ("lib/models/farmer.dart", "return 'Harvest';", "return 'Harvest'.tr;"),
    ("lib/models/farmer.dart", "return 'Procurement';", "return 'Procurement'.tr;"),
    ("lib/models/farmer.dart", "return 'Settlement Completed';", "return 'Settlement Completed'.tr;"),
    ("lib/models/farmer.dart", "return 'Proceed to cash support to activate the partnership.';", "return 'Proceed to cash support to activate the partnership.'.tr;"),
    ("lib/models/farmer.dart", "return 'Cash support has been acknowledged. Nursery preparation is next.';", "return 'Cash support has been acknowledged. Nursery preparation is next.'.tr;"),
    ("lib/models/farmer.dart", "return 'Nursery activities are underway for this farmer.';", "return 'Nursery activities are underway for this farmer.'.tr;"),
    ("lib/models/farmer.dart", "return 'Growth monitoring and planned visits are active.';", "return 'Growth monitoring and planned visits are active.'.tr;"),
    ("lib/models/farmer.dart", "return 'Harvest window is active. Procurement can be scheduled.';", "return 'Harvest window is active. Procurement can be scheduled.'.tr;"),
    ("lib/models/farmer.dart", "return 'Harvesting and procurement records are in progress or complete.';", "return 'Harvesting and procurement records are in progress or complete.'.tr;"),
    ("lib/models/farmer.dart", "return 'Reconciliation is complete for this crop cycle.';", "return 'Reconciliation is complete for this crop cycle.'.tr;"),
    
    # models/support.dart
    ("lib/models/support.dart", "return 'Received';", "return 'Received'.tr;"),
    ("lib/models/support.dart", "return 'Paid';", "return 'Paid'.tr;"),
    ("lib/models/support.dart", "return 'Acknowledged';", "return 'Acknowledged'.tr;"),
    ("lib/models/support.dart", "return 'Given';", "return 'Given'.tr;"),
    ("lib/models/support.dart", "this.itemName = 'Seeds',", "this.itemName = 'Seeds',"), # Don't translate code default
    
    # models/settlement.dart
    ("lib/models/settlement.dart", "return 'Pending Reconciliation';", "return 'Pending Reconciliation'.tr;"),
    
    # models/procurement.dart
    ("lib/models/procurement.dart", "return 'Harvesting';", "return 'Harvesting'.tr;"),
    ("lib/models/procurement.dart", "return 'Packaging';", "return 'Packaging'.tr;"),
    ("lib/models/procurement.dart", "return 'Weighing';", "return 'Weighing'.tr;"),
    ("lib/models/procurement.dart", "return 'Price';", "return 'Price'.tr;"),
    ("lib/models/procurement.dart", "return 'Receipt';", "return 'Receipt'.tr;"),
    ("lib/models/procurement.dart", "return 'Transport';", "return 'Transport'.tr;"),
    
    # state/app_state.dart
    ("lib/state/app_state.dart", "return 'All farmer details are required.';", "return 'All farmer details are required.'.tr;"),
    ("lib/state/app_state.dart", "return 'Enter a valid phone number.';", "return 'Enter a valid phone number.'.tr;"),
    ("lib/state/app_state.dart", "return 'A farmer with this phone number already exists.';", "return 'A farmer with this phone number already exists.'.tr;"),
    ("lib/state/app_state.dart", "return 'Land values must be greater than zero.';", "return 'Land values must be greater than zero.'.tr;"),
    ("lib/state/app_state.dart", "return 'Nursery and main land must add up to total land.';", "return 'Nursery and main land must add up to total land.'.tr;"),
    ("lib/state/app_state.dart", "return 'Procurement: Not started';", "return 'Procurement: Not started'.tr;"),
    ("lib/state/app_state.dart", "return 'Procurement: Submitted';", "return 'Procurement: Submitted'.tr;"),
    ("lib/state/app_state.dart", "return 'Procurement: Ready to submit';", "return 'Procurement: Ready to submit'.tr;"),
    ("lib/state/app_state.dart", "pendingSupport.id == 'temp' ? 'Start support' : 'Resume support'", "pendingSupport.id == 'temp' ? 'Start support'.tr : 'Resume support'.tr"),
    
    # screens/engagement_screens.dart
    ("lib/screens/engagement_screens.dart", "return 'Phone number is required.';", "return 'Phone number is required.'.tr;"),
    ("lib/screens/engagement_screens.dart", "return 'Enter a valid phone number.';", "return 'Enter a valid phone number.'.tr;"),
    ("lib/screens/engagement_screens.dart", "return 'A farmer with this phone number already exists.';", "return 'A farmer with this phone number already exists.'.tr;"),
    ("lib/screens/engagement_screens.dart", "return 'Nursery land and main land must add up to total land.';", "return 'Nursery land and main land must add up to total land.'.tr;"),
    
    # screens/support_screens.dart
    ("lib/screens/support_screens.dart", "return 'Select a farmer to continue.';", "return 'Select a farmer to continue.'.tr;"),
    ("lib/screens/support_screens.dart", "return 'Capture support details before generating the confirmation code.';", "return 'Capture support details before generating the confirmation code.'.tr;"),
    
    # screens/auth_screens.dart
    ("lib/screens/auth_screens.dart", "_error = 'Enter any valid 4 digit OTP to continue.';", "_error = 'Enter any valid 4 digit OTP to continue.'.tr;"),
    ("lib/screens/auth_screens.dart", "_error = 'Mock OTP resent. Use any 4 digits.';", "_error = 'Mock OTP resent. Use any 4 digits.'.tr;"),
]

for file_path, old, new in replacements:
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        content = content.replace(old, new)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)

print("Patching of returns and assignments completed.")
