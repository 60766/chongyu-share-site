#!/bin/bash

# 修复头像加载问题
echo "修复头像加载问题..."

# 检查CharacterAvatarService.swift文件
avatar_service_file="虫遇/Utils/CharacterAvatarService.swift"
if [ -f "$avatar_service_file" ]; then
  # 备份原文件
  cp "$avatar_service_file" "${avatar_service_file}.bak"
  
  # 修改getAvatarName方法，确保返回正确的路径
  sed -i '' 's|return "HistoricalFigures/\(normalizedId\)"|return normalizedId|g' "$avatar_service_file"
  
  echo "已修改 CharacterAvatarService.swift 中的 getAvatarName 方法"
fi

# 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "修复完成！请重启Xcode并清除项目缓存。"
