import os
import re

DATA_FILE = 'lib/utils/translations_data.dart'

with open(DATA_FILE, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace any sequence of backslashes followed by $ with just $
# E.g. \\$ -> $
content = re.sub(r'\\+\$', r'$', content)

# Now, replace all $ with \$
content = content.replace('$', '\\$')

with open(DATA_FILE, 'w', encoding='utf-8') as f:
    f.write(content)

print("Formatting fixed.")
