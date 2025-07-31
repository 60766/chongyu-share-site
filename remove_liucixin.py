#!/usr/bin/env python3
import json
import os
import re
import shutil

# Character to remove
character_to_remove = "liucixin"
character_name = "刘慈欣"

# 1. Remove from characters.json
json_file_path = "虫遇/Resources/characters.json"
try:
    with open(json_file_path, 'r', encoding='utf-8') as f:
        json_data = json.load(f)
    
    # Filter out the character to remove from the characters array
    if "characters" in json_data:
        json_data["characters"] = [char for char in json_data["characters"] if char.get('id') != character_to_remove]
        
        # Save the updated JSON
        with open(json_file_path, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ Removed {character_name} from characters.json")
    else:
        print(f"⚠️ No 'characters' array found in characters.json")
except Exception as e:
    print(f"❌ Error removing from characters.json: {e}")

# 2. Remove from CharacterAvatarService.swift
swift_file_path = "虫遇/Utils/CharacterAvatarService.swift"
try:
    # Read the file
    with open(swift_file_path, 'r', encoding='utf-8') as f:
        swift_content = f.read()
    
    # Remove from knownCharacters array
    # Pattern matches "liucixin" with optional quotes and comma
    pattern_array = r'["\']{}["\'],?\s*'.format(character_to_remove)
    updated_content = re.sub(pattern_array, '', swift_content)
    
    # Remove the case statement for the character
    # This pattern is more specific to match the entire case statement
    pattern_case = r'case\s+["\']{}["\']\s*:\s*return\s+\([^)]+\).*?//.*?\n'.format(character_to_remove)
    updated_content = re.sub(pattern_case, '', updated_content)
    
    # Write the updated content back
    with open(swift_file_path, 'w', encoding='utf-8') as f:
        f.write(updated_content)
    
    print(f"✅ Removed {character_name} from CharacterAvatarService.swift")
except Exception as e:
    print(f"❌ Error removing from CharacterAvatarService.swift: {e}")

# 3. Remove the imageset folder
imageset_path = f"虫遇/Assets.xcassets/HistoricalFigures/{character_to_remove}.imageset"
try:
    if os.path.exists(imageset_path):
        shutil.rmtree(imageset_path)
        print(f"✅ Removed {character_to_remove}.imageset folder")
    else:
        print(f"⚠️ {character_to_remove}.imageset folder not found")
except Exception as e:
    print(f"❌ Error removing imageset folder: {e}")

# 4. Update the README file if it exists
readme_path = "虫遇/Assets.xcassets/HistoricalFigures/README_角色头像对照表.md"
try:
    if os.path.exists(readme_path):
        with open(readme_path, 'r', encoding='utf-8') as f:
            readme_content = f.read()
        
        # Remove the line containing the character
        pattern_readme = r'\|\s*{}.*\|\s*{}.*\|\n'.format(character_to_remove, character_name)
        updated_readme = re.sub(pattern_readme, '', readme_content)
        
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(updated_readme)
        
        print(f"✅ Removed {character_name} from README file")
    else:
        print(f"⚠️ README file not found")
except Exception as e:
    print(f"❌ Error updating README file: {e}")

# 5. Also check for any backup files that might contain the character
backup_json_paths = [
    "虫遇/Resources/characters_clean.json",
    "虫遇/Resources/characters_fixed.json",
    "虫遇/Resources/characters_fixed2.json"
]

for backup_path in backup_json_paths:
    try:
        if os.path.exists(backup_path):
            with open(backup_path, 'r', encoding='utf-8') as f:
                backup_data = json.load(f)
            
            # Filter out the character if the file has the same structure
            if "characters" in backup_data:
                backup_data["characters"] = [char for char in backup_data["characters"] if char.get('id') != character_to_remove]
                
                # Save the updated JSON
                with open(backup_path, 'w', encoding='utf-8') as f:
                    json.dump(backup_data, f, ensure_ascii=False, indent=2)
                
                print(f"✅ Removed {character_name} from {backup_path}")
            else:
                print(f"⚠️ No 'characters' array found in {backup_path}")
        else:
            print(f"⚠️ Backup file {backup_path} not found")
    except Exception as e:
        print(f"❌ Error removing from {backup_path}: {e}")

# 6. Also check CopyHistoricalFigureImages.swift if it exists
copy_images_path = "虫遇/Utils/CopyHistoricalFigureImages.swift"
try:
    if os.path.exists(copy_images_path):
        with open(copy_images_path, 'r', encoding='utf-8') as f:
            copy_images_content = f.read()
        
        # Remove from any array in this file
        pattern_array = r'["\']{}["\'],?\s*'.format(character_to_remove)
        updated_content = re.sub(pattern_array, '', copy_images_content)
        
        with open(copy_images_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        
        print(f"✅ Removed {character_name} from CopyHistoricalFigureImages.swift")
    else:
        print(f"⚠️ CopyHistoricalFigureImages.swift not found")
except Exception as e:
    print(f"❌ Error removing from CopyHistoricalFigureImages.swift: {e}")

print(f"\n✅ Completed removal of {character_name} ({character_to_remove}) from the system") 