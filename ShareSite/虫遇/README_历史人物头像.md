# 历史人物头像管理指南

## 头像文件结构

所有历史人物的头像都应放在以下位置：
```
虫遇/Assets.xcassets/HistoricalFigures/{characterID}.imageset/{characterID}.png
```

例如，孔子的头像位于：
```
虫遇/Assets.xcassets/HistoricalFigures/kongzi.imageset/kongzi.png
```

## 添加新的历史人物头像

1. 在Xcode中打开Assets.xcassets
2. 右键点击HistoricalFigures文件夹，选择"New Image Set"
3. 将新创建的Image Set重命名为角色ID（全小写，如"socrates"）
4. 将头像图片拖入Image Set中
5. 确保图片文件名与角色ID一致（如"socrates.png"）

## 代码中使用历史人物头像

在代码中，通过以下方式获取历史人物头像：

```swift
// 使用CharacterAvatarService
let avatarName = CharacterAvatarService.shared.getAvatarName(for: characterID)
Image(avatarName)

// 或者直接使用路径
Image("HistoricalFigures/\(characterID)")
```

## 当前支持的历史人物ID

以下是当前系统支持的所有历史人物ID：

- einstein（爱因斯坦）
- shakespeare（莎士比亚）
- davinci（达芬奇）
- kongzi（孔子）
- newton（牛顿）
- libai（李白）
- holmes（福尔摩斯）
- curie（居里夫人）
- socrates（苏格拉底）
- plato（柏拉图）
- aristotle（亚里士多德）
- tesla（特斯拉）
- hawking（霍金）
- mozart（莫扎特）
- beethoven（贝多芬）
- freud（弗洛伊德）
- darwin（达尔文）
- sunwukong（孙悟空）
- sherlock（夏洛克）

## 注意事项

1. 所有角色ID必须全小写
2. 图片文件名必须与角色ID一致
3. 图片应为PNG格式，推荐尺寸为200x200像素
4. 为确保在运行时能正确加载图片，构建后请检查以下目录：
   ```
   build-xcodebuild/Debug-iphonesimulator/虫遇.app/HistoricalFigures/
   ```

## 故障排除

如果头像无法显示，请检查：

1. 图片是否存在于正确的位置
2. 图片文件名是否与角色ID一致
3. 代码中使用的角色ID是否与图片集名称一致
4. 运行时目录是否包含图片文件 