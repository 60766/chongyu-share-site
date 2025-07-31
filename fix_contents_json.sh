#!/bin/bash

# 这个脚本修复所有图片资源的Contents.json文件

# 遍历所有角色文件夹
for dir in 虫遇/Assets.xcassets/HistoricalFigures/*.imageset; do
  # 获取文件夹名称
  dirname=$(basename "$dir" .imageset)
  
  # 创建正确的Contents.json文件
  cat > "$dir/Contents.json" << EOT
{
  "images" : [
    {
      "filename" : "$dirname.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOT
  
  echo "已修复 $dirname.imageset/Contents.json"
done

echo "所有Contents.json文件已修复"
