#!/bin/bash

# 项目根目录
PROJECT_DIR="/Users/lishilong/IOS开发/虫遇/虫遇"

echo "=== 检查导入问题 ==="
grep -r "import 虫遇" --include="*.swift" $PROJECT_DIR

echo -e "\n=== 检查@main属性冲突 ==="
grep -r "@main" --include="*.swift" $PROJECT_DIR

echo -e "\n=== 检查SwipeDirection定义 ==="
grep -r "enum SwipeDirection" --include="*.swift" $PROJECT_DIR

echo -e "\n=== 检查TimeSpaceParticleView定义 ==="
grep -r "struct TimeSpaceParticleView" --include="*.swift" $PROJECT_DIR

echo -e "\n=== 完成 ===" 