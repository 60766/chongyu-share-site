#!/bin/bash

# 同时提供1x和3x分辨率的图片
# 这样可以确保在所有设备上都能正常显示且清晰

echo "开始设置双分辨率图片..."

# 处理关键角色
key_characters=("einstein" "shakespeare" "davinci" "kongzi" "newton")
for char in "${key_characters[@]}"; do
  char_dir="虫遇/Assets.xcassets/HistoricalFigures/${char}.imageset"
  char_png="$char_dir/${char}.png"
  
  if [ -f "$char_png" ]; then
    # 确保文件权限正确
    chmod 644 "$char_png"
    
    # 重新创建Contents.json，同时设置1x和3x
    cat > "$char_dir/Contents.json" << EOJSON
{
  "images" : [
    {
      "filename" : "${char}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${char}.png",
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
    echo "已设置双分辨率: $char"
  else
    echo "跳过: $char (图片不存在)"
  fi
done

echo "修复完成！这样设置后，同一张图片将同时用于1x和3x分辨率。"
echo "在低分辨率设备上会缩小显示，在高分辨率设备上会放大显示。"
echo "虽然不是最理想的做法，但可以确保在所有设备上都能显示图片。"
