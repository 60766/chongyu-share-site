#!/bin/bash

# 缺失头像添加脚本
# 使用方法: 将所有头像图片放在 missing_avatars 文件夹中，然后运行此脚本

# 创建临时目录
mkdir -p missing_avatars

echo "🖼️ 缺失头像添加工具"
echo "====================="
echo "请将以下角色的PNG头像图片放入 missing_avatars 文件夹:"
echo ""
echo "ahq.png          - 阿Q"
echo "anna_karenina.png - 安娜·卡列尼娜"
echo "ayuwang.png      - 阿育王"
echo "daenerys.png     - 丹妮莉丝·坦格利安"
echo "doctor.png       - 神秘博士"
echo "don_quixote.png  - 堂吉诃德"
echo "gatsby.png       - 盖茨比"
echo "gollum.png       - 咕噜"
echo "hamlet.png       - 哈姆雷特"
echo "hermione.png     - 赫敏·格兰杰"
echo "jean_valjean.png - 冉·阿让"
echo "jia_baoyu.png    - 贾宝玉"
echo "joker.png        - 小丑"
echo "liucixin.png     - 刘慈欣"
echo "macbeth.png      - 麦克白"
echo "raskolnikov.png  - 拉斯科尔尼科夫"
echo "scarlett.png     - 斯嘉丽"
echo "yuefei.png       - 岳飞"
echo ""
echo "准备好后，按回车键继续..."
read

# 检查图片是否存在
missing_count=0
for char in ahq anna_karenina ayuwang daenerys doctor don_quixote gatsby gollum hamlet hermione jean_valjean jia_baoyu joker liucixin macbeth raskolnikov scarlett yuefei; do
    if [ ! -f "missing_avatars/${char}.png" ]; then
        echo "⚠️ 警告: missing_avatars/${char}.png 不存在"
        missing_count=$((missing_count + 1))
    fi
done

if [ $missing_count -gt 0 ]; then
    echo ""
    echo "有 $missing_count 个图片文件缺失。是否继续? (y/n)"
    read answer
    if [ "$answer" != "y" ]; then
        echo "操作已取消。"
        exit 1
    fi
fi

# 复制图片到对应的文件夹
echo ""
echo "正在复制图片文件..."
for char in ahq anna_karenina ayuwang daenerys doctor don_quixote gatsby gollum hamlet hermione jean_valjean jia_baoyu joker liucixin macbeth raskolnikov scarlett yuefei; do
    if [ -f "missing_avatars/${char}.png" ]; then
        cp "missing_avatars/${char}.png" "虫遇/Assets.xcassets/HistoricalFigures/${char}.imageset/"
        echo "✅ 已添加: ${char}.png"
    fi
done

echo ""
echo "✅ 头像添加完成!"
echo "请重新编译应用以应用更改。" 