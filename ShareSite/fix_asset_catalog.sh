#!/bin/bash

# 修复Asset Catalog脚本
# 尝试通过重新注册Asset Catalog来解决头像不显示的问题

echo "开始修复Asset Catalog..."

# 1. 创建Assets.xcassets的备份
echo "创建备份..."
timestamp=$(date +%Y%m%d%H%M%S)
backup_dir="backup_assets_$timestamp"
mkdir -p "$backup_dir"
cp -R 虫遇/Assets.xcassets/HistoricalFigures "$backup_dir/"
echo "备份创建完成: $backup_dir"

# 2. 重新设置HistoricalFigures文件夹的Contents.json
echo "重新设置HistoricalFigures文件夹的Contents.json..."
cat > 虫遇/Assets.xcassets/HistoricalFigures/Contents.json << EOJSON
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOJSON

# 3. 修复一些关键角色的imageset
echo "修复关键角色的imageset..."
key_characters=("einstein" "shakespeare" "davinci" "kongzi" "newton")
for char in "${key_characters[@]}"; do
  char_dir="虫遇/Assets.xcassets/HistoricalFigures/${char}.imageset"
  char_png="$char_dir/${char}.png"
  
  if [ -f "$char_png" ]; then
    # 确保文件权限正确
    chmod 644 "$char_png"
    
    # 重新创建Contents.json
    cat > "$char_dir/Contents.json" << EOJSON
{
  "images" : [
    {
      "filename" : "${char}.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOJSON
    echo "已修复: $char"
  else
    echo "跳过: $char (图片不存在)"
  fi
done

# 4. 清理缓存
echo "清理缓存..."
find 虫遇/Assets.xcassets -name "*.DS_Store" -delete

echo "修复完成！请重新启动Xcode并清除构建文件夹。"
