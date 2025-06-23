#!/bin/bash
# 备份原始文件
cp 虫遇/Views/Components/PostCardView.swift 虫遇/Views/Components/PostCardView.swift.bak

# 删除重复定义的SwipeDirection枚举
sed -i '' '2824,2827d' 虫遇/Views/Components/PostCardView.swift

# 删除重复定义的TimeSpaceParticleView结构体
sed -i '' '2841,2933d' 虫遇/Views/Components/PostCardView.swift

# 删除重复定义的TimeSpaceRippleView结构体
sed -i '' '2934,3001d' 虫遇/Views/Components/PostCardView.swift

# 删除重复定义的FullscreenPostDetailView结构体
sed -i '' '3002,5213d' 虫遇/Views/Components/PostCardView.swift

# 添加导入语句
sed -i '' '2:i\
import SwiftData' 虫遇/Views/Components/PostCardView.swift

# 添加TimeSpaceTransitionEffect导入
sed -i '' '4:i\
// 导入TimeSpaceTransitionEffect中定义的类型\
import SwiftUI' 虫遇/Views/Components/PostCardView.swift

echo "修复完成！"
