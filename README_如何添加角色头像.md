# 如何添加新的角色头像

为了确保新角色的头像能够正确显示，请严格遵循以下步骤。这个流程能保证图片资源被正确打包，并且代码能找到它。

---

## 角色ID一致性

**重要提示**: 角色ID必须在整个系统中保持一致。具体来说：

1. 角色ID在`characters.json`文件中定义
2. 头像文件名必须与角色ID完全一致（如`kongzi.png`对应ID为`kongzi`的角色）
3. `CharacterAvatarService`中的`knownCharacters`数组必须包含该角色ID

---

## 添加新角色头像的步骤

### 第1步：准备并添加图片资源

1.  **图片要求**：
    *   **格式**：PNG (`.png`)
    *   **尺寸**：建议使用 `512x512` 像素或更高，以保证在不同分辨率下都清晰。
    *   **命名**：使用角色的英文ID，**全部小写**。例如，如果角色ID是 `newton`，图片文件名必须是 `newton.png`。

2.  **添加到Xcode项目**：
    *   在Xcode的`虫遇/Assets.xcassets/`中找到 `HistoricalFigures` 这个文件夹（如果不存在，请创建一个）。
    *   右键点击该文件夹，选择"New Image Set"，并将其命名为角色ID（如`newton`）。
    *   将准备好的 `.png` 图片文件拖入新创建的Image Set中。
    *   **验证**：添加后，确认图片在Xcode中显示正常。

---

### 第2步：更新角色列表

1.  **打开文件**：
    *   在Xcode中找到并打开 `虫遇/Utils/CharacterAvatarService.swift` 文件。

2.  **更新`knownCharacters`数组**：
    *   找到名为 `knownCharacters` 的私有属性（一个字符串数组）。
    *   将新角色的ID（**小写**）添加到这个数组中的适当分类下。

    ```swift
    // 示例：添加新的历史人物"caesar"
    private let knownCharacters = [
        // 已有的历史人物和科学家
        "einstein", "shakespeare", "davinci", "kongzi", "newton", "caesar", // <-- 在这里添加
        ...
    ]
    ```

---

### 第3步：确保JSON库一致性

1.  **检查characters.json**：
    *   确保新角色已在`虫遇/Resources/characters.json`文件中定义，并且其`id`字段与您使用的ID完全一致。
    *   如果是添加已有角色的头像，请确认JSON中的`id`和`avatarName`字段与您的头像文件名一致。

2.  **JSON示例**：
    ```json
    {
      "id": "caesar",
      "name": "凯撒",
      "type": "historical",
      "subtype": "leader",
      "era": "古罗马",
      "primaryField": "军事家、政治家",
      "briefDescription": "古罗马共和国末期的军事统帅和政治家",
      "avatarName": "caesar",
      "region": "罗马",
      "contentAffinities": {
        "古潮新语": 0.8,
        "穿越吐槽": 0.7,
        "日常心情": 0.6,
        "虫洞共鸣": 0.7,
        "时空记事": 0.9
      }
    }
    ```

---

### 第4步：运行应用并验证

1.  **运行应用**：
    *   完成以上修改后，重新编译并运行您的应用。

2.  **触发显示**：
    *   通过"邀请角色评论"等功能，触发新角色的显示。

3.  **验证结果**：
    *   检查新角色的头像是否已正确显示。如果仍然不显示，请检查控制台（Console）中的调试日志，特别是与`CharacterAvatarService`和`HistoricalFigureAvatarView`相关的日志，它们会提供详细的线索。

---

## 故障排除

如果头像不显示，请检查：

1. **文件名一致性**：确保头像文件名与角色ID完全一致，包括大小写。
2. **资源包含**：确保图片已被正确添加到项目中并包含在目标应用中。
3. **路径正确性**：检查`HistoricalFigures`文件夹是否正确创建，图片是否放在正确的位置。
4. **调试日志**：查看控制台输出，寻找与头像加载相关的日志消息。

---

遵循以上流程，您就可以确保未来添加的任何角色头像都能被系统正确识别和加载。 