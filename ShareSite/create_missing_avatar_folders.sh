#!/bin/bash

# 读取缺失头像文件夹的角色列表
missing_avatars=($(cat missing_avatars.txt))

echo "开始创建缺失的头像文件夹..."
echo "共有 ${#missing_avatars[@]} 个角色需要创建文件夹"

# 创建文件夹和Contents.json文件
for character in "${missing_avatars[@]}"; do
    # 创建文件夹
    folder_path="虫遇/Assets.xcassets/HistoricalFigures/${character}.imageset"
    mkdir -p "$folder_path"
    
    # 创建Contents.json文件
    cat > "$folder_path/Contents.json" << EOF
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "${character}.png",
      "scale" : "3x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF
    
    echo "✅ 已创建: ${character}.imageset"
done

echo ""
echo "所有文件夹创建完成！"
echo "请注意: 您需要为每个角色添加对应的PNG图片文件" 