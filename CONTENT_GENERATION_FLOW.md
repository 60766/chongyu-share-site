# 内容生成流程说明

## 功能描述
用户在虫洞探索页面选择内容类型后，点击"启动虫洞捕捉"触发AI内容生成。

## 用户体验流程

### 1. 选择内容类型
- 用户在虫洞探索页面选择内容类型（虫洞共鸣/日常心情/古潮新语/时空记事）

### 2. 点击启动按钮
- 点击"启动虫洞捕捉"按钮
- 播放2-3秒的时空特效动画（从黑洞黄色图标中心展开）

### 3. 自动返回主页
- 特效播放完成后，自动返回到主页（虫遇 tab）
- 主页帖子列表上方显示三点加载动画
- 显示文字："AI正在生成{内容类型}内容..."

### 4. 后台生成内容
- AI在后台异步生成内容
- 用户可以浏览其他已有的帖子，不会被阻塞

### 5. 生成完成
- 内容生成完成后，三点加载动画自动消失
- 新生成的内容出现在帖子列表顶部

## 技术实现

### 核心组件

1. **ContentGenerationStateManager** (`State/AppState.swift`)
   - 全局单例，管理内容生成状态
   - `isGenerating`: 是否正在生成
   - `generatingContentType`: 生成的内容类型名称

2. **ThreeDotsLoadingView** (`Views/Components/ThreeDotsLoadingView.swift`)
   - 三点跳动加载动画组件
   - 简单优雅的视觉反馈

3. **HomeView** (`Views/Home/HomeView.swift`)
   - 监听 `generationStateManager.isGenerating`
   - 在帖子列表顶部显示加载动画

4. **WormholeExplorationView** (`Views/Exploration/WormholeExplorationView.swift`)
   - 时空特效结束时触发以下步骤：
     1. 调用 `generationStateManager.startGenerating()`
     2. `dismiss()` 返回主页
     3. 异步生成内容
     4. 完成后调用 `generationStateManager.finishGenerating()`

5. **FullscreenPostDetailView** (`Views/Components/FullscreenPostDetailView.swift`)
   - 同样的逻辑，处理从帖子详情页触发的内容生成

## 文件修改清单

- ✅ `State/AppState.swift` - 添加 ContentGenerationStateManager
- ✅ `Views/Components/ThreeDotsLoadingView.swift` - 新建加载动画组件
- ✅ `Views/Home/HomeView.swift` - 添加加载动画显示逻辑
- ✅ `Views/Exploration/WormholeExplorationView.swift` - 修改特效回调逻辑
- ✅ `Views/Components/FullscreenPostDetailView.swift` - 修改特效回调逻辑

## 特点

✨ **用户友好**
- 明确的状态反馈
- 不阻塞用户操作
- 流畅的动画过渡

🚀 **性能优化**
- 异步生成，不阻塞主线程
- 生成过程中用户可以浏览其他内容

🎨 **设计美观**
- 简洁的三点加载动画
- 与整体UI风格统一
