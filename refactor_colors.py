import os
import re

directory = 'lib'

# Color mapping
replacements = {
    # Hex codes
    r'0xFF0F0F1A': '0xFF0D1117', # Background
    r'0xFF1E1E2E': '0xFF161B22', # Surface
    r'0xFF7C3AED': '0xFF39D353', # Purple -> Bright Green
    r'0xFF2563EB': '0xFF26A641', # Blue gradient -> Medium Green
    r'0xFF22C55E': '0xFF39D353', # Success Green -> Bright Green

    # Borders (Colors.white.withValues(alpha: 0.06) -> 0xFF30363D)
    r'Colors\.white\.withValues\(alpha:\s*0\.0[568]?[0-9]*\)': 'const Color(0xFF30363D)',
    r'Colors\.white\.withValues\(alpha:\s*0\.1[0-9]*\)': 'const Color(0xFF30363D)',
    
    # Text colors
    # Primary Text (alpha 0.8 to 1.0)
    r'Colors\.white\.withValues\(alpha:\s*0\.[89][0-9]*\)': 'const Color(0xFFE6EDF3)',
    r'Colors\.white(?!\.)': 'const Color(0xFFE6EDF3)', # Raw Colors.white not followed by .
    
    # Secondary Text (alpha 0.2 to 0.7)
    r'Colors\.white\.withValues\(alpha:\s*0\.[234567][0-9]*\)': 'const Color(0xFF8B949E)',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as file:
        content = file.read()
    
    original_content = content
    for pattern, replacement in replacements.items():
        content = re.sub(pattern, replacement, content)
        
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Done.")
