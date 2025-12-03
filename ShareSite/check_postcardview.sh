#!/bin/bash

# 检查PostCardView.swift文件
echo "检查PostCardView.swift文件..."

post_card_file="虫遇/Views/Components/PostCardView.swift"
if [ -f "$post_card_file" ]; then
  # 备份原文件
  cp "$post_card_file" "${post_card_file}.check_bak"
  
  # 查找未闭合的注释
  echo "查找未闭合的注释..."
  open_comments=$(grep -o "/\*" "$post_card_file" | wc -l)
  close_comments=$(grep -o "\*/" "$post_card_file" | wc -l)
  
  echo "注释检查: 开始注释 $open_comments, 结束注释 $close_comments"
  
  # 查找问题区域
  echo "查找可能有问题的区域..."
  grep -n "ImageHelper" "$post_card_file" | tail -10
  
  # 显示文件末尾内容
  echo "文件末尾内容:"
  tail -20 "$post_card_file"
  
  # 完全重写问题部分
  echo "重写可能有问题的部分..."
  
  # 提取文件前半部分直到特定行
  head -1188 "$post_card_file" > "${post_card_file}.tmp"
  
  # 添加修复后的代码
  cat >> "${post_card_file}.tmp" << EOFIX
                    } else {
                        // 使用ImageHelper加载图片
                        if ImageHelper.isCharacterAvatarAvailable(imageName) {
                            ImageHelper.loadCharacterAvatar(imageName, size: calculateSingleImageHeight(for: imageName, width: geometry.size.width * 0.85))
                                .frame(maxWidth: geometry.size.width * 0.85)
                                .cornerRadius(3)
                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                                )
                        }
                    }
EOFIX
  
  # 提取文件后半部分从特定行开始
  tail -n +1190 "$post_card_file" >> "${post_card_file}.tmp"
  
  # 替换原文件
  mv "${post_card_file}.tmp" "$post_card_file"
  
  echo "已修复PostCardView.swift"
fi

echo "检查完成！"
