# 虫遇 - 水平模态视图实现

## 项目概述

"虫遇"是一个虚构角色社交应用，允许用户与历史人物进行对话交流。本次实现的核心功能是水平滑动模态视图，以取代iOS默认的从底部向上弹出的模态视图，提供更符合现代UI设计的交互体验。

## 核心组件

### 1. 水平模态过渡修饰符

项目中实现了两种水平模态过渡修饰符：

- `HorizontalModalTransition`: 基于项目（Item）的模态转场，适用于传递数据对象到模态视图
- `HorizontalModalBoolTransition`: 基于布尔值的模态转场，适用于简单的显示/隐藏场景

这两个修饰符作为SwiftUI的ViewModifier实现，可以通过扩展View来简化使用。

### 2. 应用场景

主要应用于以下视图：

- **HomeView**: 首页视图，用于从帖子列表跳转到帖子详情
- **UserPostListView**: 用户帖子列表，同样用于跳转到帖子详情
- **FullscreenPostDetailView**: 全屏帖子详情视图，支持右滑关闭和左右滑动切换帖子

### 3. 手势交互

实现了丰富的手势交互：

- **右滑关闭**: 从右侧边缘向右滑动可以关闭模态视图
- **左右滑动切换**: 在帖子详情中可以左右滑动切换上一篇/下一篇帖子
- **视觉提示**: 滑动过程中提供边缘预览指示器和触觉反馈

## 技术实现

### 核心代码

```swift
// 基于项目的水平模态修饰符
struct HorizontalModalTransition<Item: Identifiable, Content: View>: ViewModifier {
    let item: Binding<Item?>
    let onDismiss: (() -> Void)?
    let direction: ModalDirection
    let content: (Item) -> Content
    
    @State private var slideInPosition = CGSize.zero
    @State private var activeItem: Item? = nil
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .onChange(of: item.wrappedValue) { oldValue, newValue in
                    // 处理显示和隐藏逻辑
                }
            
            if let activeItem = activeItem {
                self.content(activeItem)
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: slideInPosition.width, y: 0)
                    .transition(.identity)
                    .zIndex(999)
            }
        }
    }
}

// 使用方法
.horizontalModal(
    item: $selectedPost, 
    direction: .fromRight,
    onDismiss: {
        // 关闭回调
    }
) { post in
    // 模态内容视图
    FullscreenPostDetailView(/*...*/)
}
```

### 动画实现

采用了以下动画策略：

1. **滑入动画**: 使用弹性动画（spring）实现自然的滑入效果
2. **滑出动画**: 同样使用弹性动画实现平滑的滑出效果
3. **过渡动画**: 使用`.identity`转场避免额外的视觉干扰

## 使用说明

### 基于项目的模态视图

```swift
@State private var selectedItem: YourModel? = nil

// 在视图中使用
.horizontalModal(
    item: $selectedItem,
    direction: .fromRight,
    onDismiss: {
        // 关闭后的操作
    }
) { item in
    // 使用item构建的模态内容视图
    YourDetailView(item: item)
}

// 显示模态视图
Button("显示") {
    selectedItem = yourModelInstance
}

// 在模态视图中关闭
Button("关闭") {
    selectedItem = nil
}
```

### 基于布尔值的模态视图

```swift
@State private var showModal = false

// 在视图中使用
.horizontalModal(
    isPresented: $showModal,
    direction: .fromRight,
    onDismiss: {
        // 关闭后的操作
    }
) {
    // 模态内容视图
    YourModalView()
}

// 显示模态视图
Button("显示") {
    showModal = true
}

// 在模态视图中关闭
Button("关闭") {
    showModal = false
}
```

## 测试

项目提供了一个专门的测试视图 `HorizontalModalTestView`，可以用来测试和演示水平模态转场的效果。
