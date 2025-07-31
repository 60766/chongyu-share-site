#!/bin/bash

# 设置工作目录
ASSETS_DIR="虫遇/Assets.xcassets/HistoricalFigures"

# 检查目录是否存在
if [ ! -d "$ASSETS_DIR" ]; then
  echo "错误: 目录 $ASSETS_DIR 不存在"
  exit 1
fi

# 计数器
count=0
total=$(find "$ASSETS_DIR" -name "*.imageset" | wc -l)

# 遍历所有imageset目录
for imageset_dir in "$ASSETS_DIR"/*.imageset; do
  if [ -d "$imageset_dir" ]; then
    # 获取imageset名称
    imageset_name=$(basename "$imageset_dir" .imageset)
    
    # 查找目录中的PNG文件
    png_file=$(find "$imageset_dir" -name "*.png" | head -n 1)
    
    if [ -n "$png_file" ]; then
      # 获取PNG文件名
      png_filename=$(basename "$png_file")
      
      # 创建新的Contents.json文件
      cat > "$imageset_dir/Contents.json" << EOF
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "$png_filename",
      "scale" : "3x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF
      
      count=$((count + 1))
      echo "[$count/$total] 修复了 $imageset_name.imageset 的Contents.json文件"
    else
      echo "警告: $imageset_name.imageset 中没有找到PNG文件"
    fi
  fi
done

echo "完成! 共修复了 $count 个imageset的Contents.json文件"
