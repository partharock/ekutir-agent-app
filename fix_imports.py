import os

files_to_fix = [
    'lib/models/crop_plan.dart',
    'lib/models/farmer.dart',
    'lib/models/procurement.dart',
    'lib/models/settlement.dart',
    'lib/models/support.dart'
]

import_statement = "import '../utils/translation_service.dart';\n"

for file_path in files_to_fix:
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        if import_statement not in content:
            # We can insert it at the very top
            content = import_statement + content
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

print("Imports fixed.")
