#!/bin/bash

# 调试脚本：检查头像加载问题

# 检查一些关键角色的图片文件
echo "检查关键角色图片文件..."
key_characters=("einstein" "shakespeare" "davinci" "kongzi" "newton")
for char in "${key_characters[@]}"; do
  echo "检查 $char:"
  find 虫遇/Assets.xcassets -name "${char}.png" | while read -r file; do
    echo "  文件存在: $file"
    file_size=$(stat -f %z "$file")
    echo "  文件大小: $file_size 字节"
    file_type=$(file "$file" | cut -d: -f2-)
    echo "  文件类型: $file_type"
  done
  
  # 检查Contents.json
  json_file="虫遇/Assets.xcassets/HistoricalFigures/${char}.imageset/Contents.json"
  if [ -f "$json_file" ]; then
    echo "  Contents.json 存在"
    cat "$json_file" | grep filename
  else
    echo "  Contents.json 不存在"
  fi
  echo ""
done

# 检查Assets目录结构
echo "检查Assets目录结构..."
find 虫遇/Assets.xcassets/HistoricalFigures -type d -name "*.imageset" | wc -l

# 检查是否有空的imageset
echo "检查空的imageset..."
for dir in $(find 虫遇/Assets.xcassets/HistoricalFigures -type d -name "*.imageset"); do
  png_count=$(find "$dir" -name "*.png" | wc -l)
  if [ "$png_count" -eq 0 ]; then
    echo "空的imageset: $dir"
  fi
done

# 检查Assets缓存
echo "检查Assets缓存..."
find 虫遇/Assets.xcassets -name ".DS_Store" | wc -l

# 尝试修复爱因斯坦图片
echo "尝试修复爱因斯坦图片..."
einstein_dir="虫遇/Assets.xcassets/HistoricalFigures/einstein.imageset"
if [ -d "$einstein_dir" ]; then
  einstein_png="$einstein_dir/einstein.png"
  if [ -f "$einstein_png" ]; then
    # 确保文件权限正确
    chmod 644 "$einstein_png"
    
    # 重新创建Contents.json
    cat > "$einstein_dir/Contents.json" << EOJSON
{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "einstein.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOJSON
    echo "已重新创建爱因斯坦的Contents.json"
  else
    echo "爱因斯坦图片文件不存在"
  fi
else
  echo "爱因斯坦目录不存在"
fi

# 打印CharacterAvatarService中的关键代码路径
echo "检查代码路径..."
grep -n "getAvatarType\|getAvatarView\|checkImageExistence" 虫遇/Utils/CharacterAvatarService.swift

echo "调试完成"
