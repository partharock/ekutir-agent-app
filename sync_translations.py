import os
import re
from deep_translator import GoogleTranslator
import time

LIB_DIR = 'lib'
DATA_FILE = 'lib/utils/translations_data.dart'

LANGUAGES = {
    'English': 'en', 'Assamese': 'as', 'Bengali': 'bn', 'Bodo': 'brx', 'Dogri': 'doi', 
    'Gujarati': 'gu', 'Hindi': 'hi', 'Kannada': 'kn', 'Kashmiri': 'ks', 'Konkani': 'gom', 
    'Maithili': 'mai', 'Malayalam': 'ml', 'Manipuri': 'mni', 'Marathi': 'mr', 'Nepali': 'ne', 
    'Odia': 'or', 'Punjabi': 'pa', 'Sanskrit': 'sa', 'Santali': 'sat', 'Sindhi': 'sd', 
    'Tamil': 'ta', 'Telugu': 'te', 'Urdu': 'ur'
}

# 1. First, parse existing translations_data.dart
existing_data = {lang_name: {} for lang_name in LANGUAGES.keys()}
current_lang = None

if os.path.exists(DATA_FILE):
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
        
    lines = content.split('\n')
    for line in lines:
        for lang_name in LANGUAGES.keys():
            if line.strip() == f"'{lang_name}': {{":
                current_lang = lang_name
                break
            
        if current_lang and "': '" in line:
            parts = line.split("': '")
            if len(parts) >= 2:
                key = parts[0].split("'")[-1]
                val = parts[1].rsplit("',", 1)[0]
                existing_data[current_lang][key] = val

# 2. Find all strings in .dart files that are called with .tr
required_strings = set()
tr_pattern = re.compile(r"'([^']+)'\.tr")

for root, _, files in os.walk(LIB_DIR):
    for filename in files:
        if filename.endswith(".dart") and "translation" not in filename:
            with open(os.path.join(root, filename), "r", encoding="utf-8") as f:
                content = f.read()
            matches = tr_pattern.findall(content)
            for m in matches:
                if '\n' not in m and '$' not in m:
                    required_strings.add(m)

# Determine missing
missing_strings = [s for s in required_strings if s not in existing_data['English']]
print(f"Total `.tr` strings in codebase: {len(required_strings)}")
print(f"Missing from dictionary: {len(missing_strings)}")
for m in missing_strings:
    print(f" - {m}")

# Add existing strings into english list if they aren't there but map exists
for s in missing_strings:
    existing_data['English'][s] = s

# 3. Translate missing
for idx, s in enumerate(missing_strings):
    for lang_name, lang_code in LANGUAGES.items():
        if lang_name == 'English':
            continue
            
        print(f"Translating missing {idx+1}/{len(missing_strings)} '{s}' to {lang_name}...")
        try:
            google_lang = lang_code
            if lang_code == 'brx': google_lang = 'hi' 
            if lang_code == 'ks': google_lang = 'ur'
            if lang_code == 'mni': google_lang = 'bn'
            if lang_code == 'sat': google_lang = 'or'
            
            translated = GoogleTranslator(source='en', target=google_lang).translate(s)
            
            translated = translated.replace("'", "\\'").replace("$", "\\$")
            existing_data[lang_name][s] = translated
        except Exception as e:
            print(f"Translation failed for {s} to {lang_name}: {e}")
            existing_data[lang_name][s] = s
        time.sleep(0.1)

# 4. Rewrite the file
with open(DATA_FILE, 'w', encoding='utf-8') as f:
    f.write('const Map<String, Map<String, String>> appTranslations = {\n')
    for lang_name in LANGUAGES.keys():
        f.write(f"  '{lang_name}': {{\n")
        all_keys = sorted(list(existing_data['English'].keys()))
        for key in all_keys:
            val = existing_data[lang_name].get(key, key)
            safe_key = key.replace("'", "\\'").replace("$", "\\$")
            if val is None:
                val = safe_key
            f.write(f"    '{safe_key}': '{val}',\n")
        f.write("  },\n")
    f.write('};\n')

print("Sync complete.")
