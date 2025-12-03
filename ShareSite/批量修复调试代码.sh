#!/bin/bash

# 批量修复调试代码脚本
# 为所有未保护的print语句添加#if DEBUG保护

echo "🔧 开始批量修复调试代码..."
echo "=================================="
echo ""

SWIFT_FILES_DIR="虫遇"
TEMP_DIR=$(mktemp -d)
BACKUP_DIR="backup_before_debug_fix_$(date +%Y%m%d_%H%M%S)"

# 创建备份目录
mkdir -p "$BACKUP_DIR"
echo "📦 备份目录: $BACKUP_DIR"
echo ""

# 统计信息
TOTAL_FILES=0
FIXED_FILES=0
TOTAL_PRINTS=0
FIXED_PRINTS=0

# 查找所有Swift文件
find "$SWIFT_FILES_DIR" -name "*.swift" -type f | while read file; do
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    # 检查文件是否包含print语句
    if grep -q "print(" "$file"; then
        # 统计print数量
        PRINT_COUNT=$(grep -c "print(" "$file" || echo "0")
        TOTAL_PRINTS=$((TOTAL_PRINTS + PRINT_COUNT))
        
        # 检查是否已有#if DEBUG保护
        if ! grep -q "#if DEBUG" "$file"; then
            # 备份文件
            cp "$file" "$BACKUP_DIR/$(basename "$file").backup"
            
            # 创建临时文件
            TEMP_FILE="$TEMP_DIR/$(basename "$file")"
            
            # 使用sed添加#if DEBUG保护
            # 注意：这是一个简单的实现，可能需要手动调整
            awk '
            BEGIN { in_debug_block = 0 }
            /^[[:space:]]*#if DEBUG/ { in_debug_block = 1 }
            /^[[:space:]]*#endif/ { in_debug_block = 0 }
            /print\(/ && !in_debug_block {
                # 检查是否已经在某个条件块中
                if (!in_debug_block) {
                    print "#if DEBUG"
                    in_debug_block = 1
                }
            }
            { print }
            ' "$file" > "$TEMP_FILE"
            
            # 替换原文件
            mv "$TEMP_FILE" "$file"
            
            FIXED_FILES=$((FIXED_FILES + 1))
            echo "✅ 已修复: $file"
        fi
    fi
done

echo ""
echo "=================================="
echo "📊 修复统计:"
echo "  总文件数: $TOTAL_FILES"
echo "  修复文件数: $FIXED_FILES"
echo "  总print语句: $TOTAL_PRINTS"
echo ""
echo "⚠️  注意：此脚本是自动化修复，可能需要手动检查和调整"
echo "📦 备份已保存到: $BACKUP_DIR"
echo ""
echo "✅ 修复完成！"

