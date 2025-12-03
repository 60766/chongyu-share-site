#!/bin/bash

# 修复父级Contents.json文件
echo "修复HistoricalFigures文件夹的Contents.json..."

# 创建标准的父级Contents.json文件
cat > 虫遇/Assets.xcassets/HistoricalFigures/Contents.json << EOJSON
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "provides-namespace" : true
  }
}
EOJSON

echo "修复完成！"
