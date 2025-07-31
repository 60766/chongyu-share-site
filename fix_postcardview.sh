#!/bin/bash

# 修复PostCardView.swift文件
echo "修复PostCardView.swift..."

# 定义文件路径
file="虫遇/Views/Components/PostCardView.swift"

# 检查文件是否存在
if [ ! -f "$file" ]; then
  echo "文件不存在: $file"
  exit 1
fi

# 备份原文件
cp "$file" "${file}.bak_before_fix"

# 使用awk来修复文件
awk '
# 标记需要删除的代码块
/else \{/ && /ImageHelper/ {
  in_block = 1
  block_level = 1
  print
  next
}
in_block && /\{/ {
  block_level++
}
in_block && /\}/ {
  block_level--
  if (block_level == 0) {
    in_block = 0
  }
  next
}
!in_block {
  print
}
' "$file" > "${file}.tmp"

# 替换原文件
if [ -s "${file}.tmp" ]; then
  mv "${file}.tmp" "$file"
  echo "已修复: $file"
else
  echo "修复失败，请检查脚本"
  rm -f "${file}.tmp"
fi

# 格式化代码（如果安装了swift-format）
if command -v swift-format &> /dev/null; then
  echo "正在格式化代码..."
  swift-format -i "$file"
fi

echo "修复完成！"
