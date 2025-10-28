import os
import re

# Directory to search
base_dir = "lib"
# Regex to catch asset image references
image_pattern = re.compile(
    r'["\'](assets/images/.*?\.(png|jpg|jpeg|svg))["\']', re.IGNORECASE
)

image_usage = {}

for root, _, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                for idx, line in enumerate(f, 1):
                    for match in image_pattern.finditer(line):
                        asset_path = match.group(1)
                        usage_info = f"{filepath}:{idx}"
                        if asset_path not in image_usage:
                            image_usage[asset_path] = []
                        image_usage[asset_path].append(usage_info)

print("\nImages referenced in Dart code and where they're used:")
if image_usage:
    for asset, locations in sorted(image_usage.items()):
        print(f"{asset}")
        for loc in locations:
            print(f"  used at: {loc}")
else:
    print("No images found.")
