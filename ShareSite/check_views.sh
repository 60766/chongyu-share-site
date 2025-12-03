#!/bin/bash

# 检查视图代码中的头像加载方式
echo "检查视图代码中的头像加载方式..."

# 查找可能显示头像的视图文件
echo "查找可能显示头像的视图文件:"
find 虫遇/Views -type f -name "*.swift" -exec grep -l "Image(" {} \; | head -10

# 检查一些关键视图文件
key_files=(
  "虫遇/Views/Components/CharacterAvatarView.swift"
  "虫遇/Views/Components/Avatar.swift"
  "虫遇/Views/Components/PostCardView.swift"
  "虫遇/Views/Components/FullscreenPostDetailView.swift"
)

for file in "${key_files[@]}"; do
  if [ -f "$file" ]; then
    echo "====== $file 内容 ======"
    grep -A 10 -B 5 "Image(" "$file" | head -20
    echo
  fi
done

# 检查图片资源的使用方式
echo "检查图片资源的使用方式:"
find 虫遇 -type f -name "*.swift" -exec grep -l "UIImage(named:" {} \; | head -5

# 查看一个示例
sample_file=$(find 虫遇 -type f -name "*.swift" -exec grep -l "UIImage(named:" {} \; | head -1)
if [ ! -z "$sample_file" ]; then
  echo "====== $sample_file 内容 ======"
  grep -A 5 -B 5 "UIImage(named:" "$sample_file" | head -15
fi

echo "检查完成！"
