# Vision API 网络连接问题修复记录

## 问题描述
在发布多张图片（特别是6-9张）时，iOS客户端调用豆包Vision API会出现"网络连接丢失"错误（URLError Code -1005）。

## 问题原因
在 `DoubaoVisionService.swift` 中存在配置冲突：
- URLSessionConfiguration 设置了 300 秒超时
- 但 URLRequest 的 `timeoutInterval` 被硬编码为 60 秒
- **URLRequest 的超时设置会覆盖 URLSessionConfiguration 的设置**

当处理多张图片时：
1. 图片需要转换为 base64 并上传
2. Vision API 需要时间处理多张图片
3. 总处理时间可能超过 60 秒
4. 导致请求超时，连接被中断

## 修复方案
移除 URLRequest 中的 `timeoutInterval` 设置，让其使用 URLSessionConfiguration 的 300 秒超时配置。

### 修改位置
1. **analyzeImagesBatch 方法**（第 211 行）
2. **analyzeImages 方法**（第 315 行）

### 修改内容
```swift
// 修改前：
request.timeoutInterval = 60.0  // 增加超时时间到60秒

// 修改后：
// ⚠️ 不设置request.timeoutInterval，使用URLSessionConfiguration的超时设置（300秒）
```

## 技术细节

### iOS 超时机制
- `timeoutIntervalForRequest`: 单个请求的超时时间（从发送到接收第一个字节）
- `timeoutIntervalForResource`: 整个资源传输的超时时间
- `URLRequest.timeoutInterval`: 会覆盖 Configuration 的设置

### 优先级
```
URLRequest.timeoutInterval > URLSessionConfiguration.timeoutIntervalForRequest
```

## 测试验证

### 服务器端测试（已通过）
```bash
# 使用 curl 测试 9 张图片
curl -X POST http://121.40.184.29:3000/api/vision \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: xxx" \
  --max-time 300 \
  -d @vision_test_9images.json

# 结果：✅ 成功返回，处理时间约 45 秒
```

### iOS 客户端测试（待验证）
1. 发布包含 6-9 张图片的帖子
2. 观察是否能成功生成 AI 评论
3. 检查日志中的处理时间

## 预期效果
- ✅ 支持最多 9 张图片的帖子
- ✅ 不再出现 60 秒超时错误
- ✅ 充分利用 300 秒的超时窗口
- ✅ 与 AINetworkService 保持一致的超时策略

## 相关文件
- `/虫遇/Services/DoubaoVisionService.swift`
- `/虫遇/Services/AINetworkService.swift`（参考配置）

## 修复日期
2025-11-07

## 备注
- 服务器端 Vision API 工作正常，无需修改
- 问题仅存在于 iOS 客户端的网络配置
- 修复后需要重新编译 iOS 应用进行测试

