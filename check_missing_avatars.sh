#!/bin/bash

echo "🔍 检查缺失的头像文件..."

# 获取所有角色ID
characters=(
    "daenerys" "hermione" "don_quixote" "hamlet" "jean_valjean" 
    "anna_karenina" "gatsby" "ahq" "scarlett" "raskolnikov" 
    "jia_baoyu" "macbeth" "joker" "gollum"
)

missing_count=0

for char in "${characters[@]}"; do
    if [ ! -d "虫遇/Assets.xcassets/HistoricalFigures/${char}.imageset" ]; then
        echo "❌ 缺失: ${char}.imageset"
        ((missing_count++))
    else
        echo "✅ 存在: ${char}.imageset"
    fi
done

echo ""
echo "📊 统计结果:"
echo "总检查角色数: ${#characters[@]}"
echo "缺失头像数: ${missing_count}"
echo "存在头像数: $((${#characters[@]} - missing_count))"

if [ $missing_count -gt 0 ]; then
    echo ""
    echo "💡 建议:"
    echo "1. 为缺失的角色创建 .imageset 目录"
    echo "2. 添加对应的 PNG 图片文件"
    echo "3. 或者使用 CharacterAvatarService 中的系统图标作为默认头像"
fi 