#!/usr/bin/env python3
import json
import os
import shutil
import re

# 要删除的角色列表
characters_to_remove = [
    "amaterasu",
    "female_ninja",
    "ghibli",
    "huluwa",
    "jojo",
    "lisiming",
    "nieying",
    "zhouxingchi"
]

print("开始删除角色...")

# 1. 从characters.json文件中删除角色
characters_path = os.path.join('虫遇', 'Resources', 'characters.json')
with open(characters_path, 'r', encoding='utf-8') as f:
    characters_data = json.load(f)

# 记录原始数量
original_count = len(characters_data['characters'])

# 过滤掉要删除的角色
characters_data['characters'] = [c for c in characters_data['characters'] if c['id'] not in characters_to_remove]

# 记录删除后的数量
new_count = len(characters_data['characters'])
removed_count = original_count - new_count

# 保存更新后的文件
with open(characters_path, 'w', encoding='utf-8') as f:
    json.dump(characters_data, f, ensure_ascii=False, indent=2)

print(f"✅ 已从characters.json中删除{removed_count}个角色")

# 2. 从CharacterAvatarService.swift中删除角色
avatar_service_path = os.path.join('虫遇', 'Utils', 'CharacterAvatarService.swift')
with open(avatar_service_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 删除knownCharacters数组中的角色
for char in characters_to_remove:
    # 使用正则表达式匹配角色名，确保它是一个完整的字符串
    pattern = f'"{char}"\\s*,\\s*'
    content = re.sub(pattern, '', content)
    # 处理可能的最后一个元素（没有逗号）
    pattern = f'\\s*,\\s*"{char}"'
    content = re.sub(pattern, '', content)

# 删除getIconAndColor函数中的角色case
for char in characters_to_remove:
    # 匹配整个case语句行
    pattern = f'\\s*case "{char}":.+?\\n'
    content = re.sub(pattern, '', content)

# 保存更新后的文件
with open(avatar_service_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"✅ 已从CharacterAvatarService.swift中删除角色")

# 3. 删除角色的头像文件夹
for char in characters_to_remove:
    imageset_path = os.path.join('虫遇', 'Assets.xcassets', 'HistoricalFigures', f'{char}.imageset')
    if os.path.exists(imageset_path):
        shutil.rmtree(imageset_path)
        print(f"✅ 已删除头像文件夹: {char}.imageset")
    else:
        print(f"⚠️ 头像文件夹不存在: {char}.imageset")

print("\n✅ 角色删除完成!")
print(f"总共删除了{removed_count}个角色")
print("请重新编译应用以应用更改") 