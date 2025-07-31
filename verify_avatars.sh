#!/bin/bash

echo "🔍 验证所有角色是否都有头像文件夹..."

# 从CharacterAvatarService.swift文件中提取所有已知角色
sed -n '/private let knownCharacters = \[/,/\]/p' 虫遇/Utils/CharacterAvatarService.swift | grep -o '"[^"]*"' | sed 's/"//g' | grep -v "^$" | sort > all_characters.txt

# 统计字符数
total_characters=$(wc -l < all_characters.txt)
echo "总角色数: $total_characters"

# 获取已存在的头像文件夹
find 虫遇/Assets.xcassets/HistoricalFigures -type d -name "*.imageset" | sed 's/.*\/\(.*\)\.imageset/\1/' | sort > existing_avatars.txt
total_folders=$(wc -l < existing_avatars.txt)
echo "已存在头像文件夹数: $total_folders"

# 找出缺少头像文件夹的角色
comm -23 all_characters.txt existing_avatars.txt > missing_avatars.txt
missing_count=$(wc -l < missing_avatars.txt)

echo "📊 统计结果:"
echo "总角色数: $total_characters"
echo "现有头像文件夹数: $total_folders"
echo "仍然缺失的头像文件夹数: $missing_count"

if [ $missing_count -gt 0 ]; then
    echo ""
    echo "⚠️ 警告: 以下角色仍然缺少头像文件夹:"
    cat missing_avatars.txt
else
    echo ""
    echo "✅ 恭喜! 所有角色都有对应的头像文件夹了!"
fi

echo ""
echo "📝 后续步骤:"
echo "1. 为每个角色添加合适的PNG头像图片"
echo "2. 重新编译应用以应用更改"
echo "3. 如果有新角色添加，请运行 ./extract_characters.sh 和 ./create_missing_avatar_folders.sh 创建新的头像文件夹" 