#!/bin/bash

# 脚本：修复图片资源文件 (第三版)
# 使用更彻底的方法修复所有imageset

# 重置所有imageset文件夹
reset_all_imagesets() {
  echo "正在重置所有imageset文件夹..."
  
  # 找到所有有PNG文件的imageset文件夹
  for dir in $(find 虫遇/Assets.xcassets/HistoricalFigures -type d -name "*.imageset"); do
    # 检查是否存在PNG文件
    png_files=$(find "$dir" -name "*.png")
    if [ -z "$png_files" ]; then
      continue
    fi
    
    # 备份当前状态
    mkdir -p "$dir/backup"
    cp "$dir"/*.png "$dir/backup/" 2>/dev/null
    
    # 删除所有文件，保留备份
    find "$dir" -type f -not -path "$dir/backup/*" -delete
    
    # 从备份恢复PNG文件
    cp "$dir/backup"/*.png "$dir/" 2>/dev/null
    
    # 删除备份
    rm -rf "$dir/backup"
    
    # 获取PNG文件名
    png_file=$(find "$dir" -name "*.png" | head -1)
    if [ -z "$png_file" ]; then
      continue
    fi
    filename=$(basename "$png_file")
    
    # 创建全新的Contents.json
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
    
    echo "已重置: $dir"
  done
}

# 清理缓存文件
clean_cache() {
  echo "清理Xcode缓存..."
  find 虫遇/Assets.xcassets -name "*.DS_Store" -delete
  
  # 确保文件权限正确
  find 虫遇/Assets.xcassets/HistoricalFigures -type f -name "*.png" -exec chmod 644 {} \;
  find 虫遇/Assets.xcassets/HistoricalFigures -type f -name "Contents.json" -exec chmod 644 {} \;
  find 虫遇/Assets.xcassets/HistoricalFigures -type d -exec chmod 755 {} \;
}

# 执行修复
echo "开始彻底修复图片资源..."
reset_all_imagesets
clean_cache
echo "修复完成！请完全关闭Xcode后重新打开项目。"
