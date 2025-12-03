#!/bin/bash
# 创建临时文件
cp 虫遇/ViewModels/PostViewModel.swift 虫遇/ViewModels/PostViewModel.swift.tmp

# 使用sed修复文件
cat > 虫遇/ViewModels/PostViewModel.swift.fixed << 'EOL'
                                    username: commentItem.characterName,
                                    userAvatar: commentItem.characterAvatar ?? "default_avatar",
                                    content: commentItem.content,
                                    datePosted: commentItem.timestamp,
                                    isVirtualCharacter: true,
                                    characterID: commentItem.characterId,
                                    parentCommentId: commentItem.parentCommentId != nil ? UUID(uuidString: commentItem.parentCommentId!) : nil,
                                    likes: commentItem.likes,
                                    isLikedByCurrentUser: Bool.random()
                                )
EOL

# 替换有问题的行
sed -e '/username: commentItem.characterName,/,/\s*\)/ {
    /username: commentItem.characterName,/p
    /userAvatar: commentItem.characterAvatar ?? "default_avatar",/p
    /content: commentItem.content,/p
    /datePosted: commentItem.timestamp,/p
    /isVirtualCharacter: true,/d
    /characterID: commentItem.characterId,/d
    /parentCommentId:/d
    /likes:/d
    /isLikedByCurrentUser:/d
    /\s*\)/d
}' 虫遇/ViewModels/PostViewModel.swift.tmp > 虫遇/ViewModels/PostViewModel.swift.temp

# 将修复后的行插入到文件中
sed '/username: commentItem.characterName,/,/\s*\)/ {
    /username: commentItem.characterName,/ {
        r 虫遇/ViewModels/PostViewModel.swift.fixed
        d
    }
    /userAvatar: commentItem.characterAvatar ?? "default_avatar",/d
    /content: commentItem.content,/d
    /datePosted: commentItem.timestamp,/d
    /isVirtualCharacter: true,/d
    /characterID: commentItem.characterId,/d
    /parentCommentId:/d
    /likes:/d
    /isLikedByCurrentUser:/d
    /\s*\)/d
}' 虫遇/ViewModels/PostViewModel.swift.temp > 虫遇/ViewModels/PostViewModel.swift

# 清理临时文件
rm 虫遇/ViewModels/PostViewModel.swift.tmp 虫遇/ViewModels/PostViewModel.swift.temp 虫遇/ViewModels/PostViewModel.swift.fixed
