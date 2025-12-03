#!/bin/bash

# 生成角色头像占位图的脚本
# 此脚本会为characters.json中的所有角色创建占位头像

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}开始生成角色头像占位图...${NC}"

# 确保目标目录存在
TARGET_DIR="虫遇/Assets.xcassets/HistoricalFigures"
mkdir -p "$TARGET_DIR"

# 从characters.json中提取所有角色ID
echo -e "${YELLOW}从characters.json中提取角色ID...${NC}"
CHARACTER_IDS=$(grep -o '"id": "[^"]*"' 虫遇/Resources/characters.json | cut -d'"' -f4)

# 计数器
TOTAL_CHARACTERS=0
CREATED_IMAGES=0
EXISTING_IMAGES=0

# 遍历所有角色ID
for ID in $CHARACTER_IDS; do
    TOTAL_CHARACTERS=$((TOTAL_CHARACTERS+1))
    
    # 检查是否已存在头像
    IMAGESET_DIR="$TARGET_DIR/$ID.imageset"
    if [ -d "$IMAGESET_DIR" ]; then
        echo -e "${YELLOW}角色 $ID 的头像已存在，跳过...${NC}"
        EXISTING_IMAGES=$((EXISTING_IMAGES+1))
        continue
    fi
    
    # 创建.imageset目录
    mkdir -p "$IMAGESET_DIR"
    
    # 创建Contents.json文件
    cat > "$IMAGESET_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "$ID.png",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF
    
    # 检查是否有kongzi.png作为模板
    if [ -f "虫遇/Assets.xcassets/HistoricalFigures/kongzi.imageset/kongzi.png" ]; then
        # 复制kongzi.png作为占位图
        cp "虫遇/Assets.xcassets/HistoricalFigures/kongzi.imageset/kongzi.png" "$IMAGESET_DIR/$ID.png"
        echo -e "${GREEN}为角色 $ID 创建了占位头像${NC}"
        CREATED_IMAGES=$((CREATED_IMAGES+1))
    else
        echo -e "${RED}错误: 找不到模板图片 kongzi.png${NC}"
    fi
done

echo -e "${BLUE}头像生成完成!${NC}"
echo -e "${GREEN}总角色数: $TOTAL_CHARACTERS${NC}"
echo -e "${GREEN}已存在头像: $EXISTING_IMAGES${NC}"
echo -e "${GREEN}新创建头像: $CREATED_IMAGES${NC}"
echo -e "${YELLOW}注意: 这些是占位图像，建议在正式使用前替换为实际的角色头像。${NC}" 