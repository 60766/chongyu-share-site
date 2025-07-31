#!/bin/bash

# 直接从knownCharacters数组中提取角色ID
sed -n '/private let knownCharacters = \[/,/\]/p' 虫遇/Utils/CharacterAvatarService.swift | grep -o '"[^"]*"' | sed 's/"//g' | grep -v "^$" | sort > all_characters.txt

# 统计字符数
echo "所有已知角色数量: $(wc -l < all_characters.txt)"

# 获取已存在的头像文件夹
ls -1 虫遇/Assets.xcassets/HistoricalFigures/ | grep ".imageset" | sed 's/\.imageset//' | sort > existing_avatars.txt
echo "已存在头像文件夹数量: $(wc -l < existing_avatars.txt)"

# 找出缺少头像文件夹的角色
comm -23 all_characters.txt existing_avatars.txt > missing_avatars.txt
echo "缺少头像文件夹的角色数量: $(wc -l < missing_avatars.txt)"

# 显示缺少头像文件夹的角色
echo "缺少头像文件夹的角色:"
cat missing_avatars.txt 