#!/bin/bash

# 这个脚本将所有角色头像图片从1x槽位移动到3x槽位

# 遍历所有角色文件夹
for dir in 虫遇/Assets.xcassets/HistoricalFigures/*.imageset; do
  # 获取文件夹名称
  dirname=$(basename "$dir" .imageset)
  
  # 检查是否有1x图片
  if [ -f "$dir/$dirname.png" ]; then
    # 创建Contents.json备份
    cp "$dir/Contents.json" "$dir/Contents.json.bak"
    
    # 修改Contents.json文件，将图片从1x移动到3x
    sed -i '' 's/"scale" : "1x"/"scale" : "3x"/g' "$dir/Contents.json"
    
    echo "已将 $dirname.png 从1x移动到3x槽位"
  fi
done

echo "所有图片已移动到3x槽位"
