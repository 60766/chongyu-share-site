#!/bin/bash

# 检查代码中如何加载头像
echo "检查代码中如何加载头像..."

# 查找可能加载头像的代码
echo "查找Avatar相关代码:"
find 虫遇 -type f -name "*.swift" -exec grep -l "Avatar" {} \; | head -5

# 查看具体实现
for file in $(find 虫遇 -type f -name "*.swift" -exec grep -l "Avatar" {} \; | head -3); do
  echo "====== $file 内容 ======"
  grep -A 10 -B 10 "Avatar" "$file" | head -20
  echo
done

# 查找CharacterAvatarService的使用
echo "查找CharacterAvatarService的使用:"
find 虫遇 -type f -name "*.swift" -exec grep -l "CharacterAvatarService" {} \; | head -5

# 查看一个示例
sample_file=$(find 虫遇 -type f -name "*.swift" -exec grep -l "CharacterAvatarService" {} \; | head -1)
if [ ! -z "$sample_file" ]; then
  echo "====== $sample_file 内容 ======"
  grep -A 10 -B 5 "CharacterAvatarService" "$sample_file" | head -20
fi

echo "检查完成！"
