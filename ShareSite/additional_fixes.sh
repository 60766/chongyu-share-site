#!/bin/bash

# 额外的修复步骤
echo "执行额外的修复步骤..."

# 1. 检查CharacterAvatarView.swift文件
echo "检查CharacterAvatarView.swift文件..."
avatar_view_file=$(find 虫遇 -name "CharacterAvatarView.swift")
if [ -f "$avatar_view_file" ]; then
  echo "找到 $avatar_view_file，检查其内容..."
  grep -A 10 "Image" "$avatar_view_file"
fi

# 2. 确保所有图片文件名与其文件夹名一致
echo "确保所有图片文件名与其文件夹名一致..."
for dir in $(find 虫遇/Assets.xcassets/HistoricalFigures -type d -name "*.imageset"); do
  base_name=$(basename "$dir" .imageset)
  png_file=$(find "$dir" -name "*.png" | head -1)
  if [ -z "$png_file" ]; then
    continue
  fi
  
  png_name=$(basename "$png_file")
  expected_name="${base_name}.png"
  
  if [ "$png_name" != "$expected_name" ]; then
    echo "修复 $dir 中的图片文件名: $png_name -> $expected_name"
    cp "$png_file" "$dir/$expected_name"
    
    # 更新Contents.json
    cat > "$dir/Contents.json" << EOJSON
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
      "filename" : "$expected_name",
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
  fi
done

# 3. 检查示例头像文件
echo "检查示例头像文件..."
for sample in einstein shakespeare davinci kongzi; do
  dir="虫遇/Assets.xcassets/HistoricalFigures/${sample}.imageset"
  if [ -d "$dir" ]; then
    echo "检查 $sample:"
    ls -la "$dir"
    cat "$dir/Contents.json"
    echo
  fi
done

echo "额外修复完成！"
