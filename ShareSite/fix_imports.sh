#!/bin/bash
# 设置文件路径
FILE="虫遇/Views/Components/FullscreenPostDetailView.swift"
BACKUP="${FILE}.backup_$(date +%Y%m%d%H%M%S)"

# 创建备份
cp "$FILE" "$BACKUP"
echo "已创建备份: $BACKUP"

# 创建临时文件
cat > temp_fix.swift << "END"
import SwiftUI
import Combine
import UIKit
import SwiftData
import AVKit
import TimeSpaceTransitionEffect

// 导入NavigationHelper
// 由于无法直接导入Utils模块，我们在此处定义所需的辅助类
END

# 提取FPDVNavigationHelper类及其后的所有内容
sed -n '/fileprivate class FPDVNavigationHelper/,$p' "$FILE" >> temp_fix.swift
