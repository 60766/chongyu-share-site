#!/bin/bash

# 修复重复的图片引用问题
echo "修复重复的图片引用问题..."

# 处理所有imageset文件夹
for dir in $(find 虫遇/Assets.xcassets/HistoricalFigures -type d -name "*.imageset"); do
  json_file="$dir/Contents.json"
  if [ ! -f "$json_file" ]; then
    continue
  fi
  
  # 检查是否有PNG文件
  png_file=$(find "$dir" -name "*.png" | head -1)
  if [ -z "$png_file" ]; then
    continue
  fi
  
  # 获取PNG文件名
  filename=$(basename "$png_file")
  
  # 创建正确的Contents.json文件
  cat > "$json_file" << EOJSON
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
      "filename" : "$filename",
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
  
  echo "已修复: $dir"
done

echo "修复完成！"
