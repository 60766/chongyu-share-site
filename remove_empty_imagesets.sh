#!/bin/bash

# 定义要删除的空 .imageset 文件夹列表
EMPTY_IMAGESETS=(
  "default_avatar"
  "hamlet"
  "don_quixote"
  "ayuwang"
  "ahq"
  "macbeth"
  "hermione"
  "jean_valjean"
  "gollum"
  "raskolnikov"
  "scarlett"
  "anna_karenina"
  "gatsby"
)

# 定义 Assets.xcassets 目录路径
ASSETS_DIR="虫遇/Assets.xcassets/HistoricalFigures"

# 检查目录是否存在
if [ ! -d "$ASSETS_DIR" ]; then
  echo "❌ 错误: 目录 $ASSETS_DIR 不存在"
  exit 1
fi

# 删除空的 .imageset 文件夹
for imageset in "${EMPTY_IMAGESETS[@]}"; do
  imageset_path="$ASSETS_DIR/${imageset}.imageset"
  
  if [ -d "$imageset_path" ]; then
    echo "🗑️ 删除空的 .imageset 文件夹: $imageset_path"
    rm -rf "$imageset_path"
  else
    echo "⚠️ 文件夹不存在: $imageset_path"
  fi
done

echo "✅ 完成删除空的 .imageset 文件夹"

# 更新 CharacterAvatarService.swift 中的 knownMissingImages 列表
AVATAR_SERVICE_FILE="虫遇/Utils/CharacterAvatarService.swift"

if [ -f "$AVATAR_SERVICE_FILE" ]; then
  echo "📝 更新 CharacterAvatarService.swift 中的 knownMissingImages 列表"
  
  # 使用 sed 更新 knownMissingImages 列表
  # 注意: 这个操作可能需要根据实际文件内容进行调整
  sed -i '' 's/let knownMissingImages = \[.*\]/let knownMissingImages = \[\]/' "$AVATAR_SERVICE_FILE"
  
  echo "✅ 已更新 CharacterAvatarService.swift"
else
  echo "❌ 错误: 文件 $AVATAR_SERVICE_FILE 不存在"
fi 