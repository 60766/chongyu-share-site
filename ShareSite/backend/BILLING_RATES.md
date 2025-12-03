# API 计费费率说明

## 当前费率设置

### 文本 API
- **模型**: `deepseek-r1-250120`
- **费率**: **16.3 积分/1k tokens**
- **计费方式**: 按总 tokens 数量计费（prompt + completion）
- **向上取整**: `ceil((total_tokens / 1000) * 16.3)`

### 图片分析 API
- **模型**: `doubao-vision-pro-32k`
- **费率**: **10.4 积分/1k tokens**
- **计费方式**: 按总 tokens 数量计费（prompt + completion）
- **向上取整**: `ceil((total_tokens / 1000) * 10.4)`

## 费率验证

运行以下命令验证费率设置：

```bash
# 验证文本API费率
./verify-rate.sh

# 验证图片API费率
./verify-image-rate.sh
```

## 费率对照表

| API 类型 | 模型 | 费率 (积分/1k tokens) | 示例用量 | 扣费 |
|---------|------|---------------------|---------|-----|
| 文本 | deepseek-r1-250120 | 16.3 | 100 tokens | 2 积分 |
| 文本 | deepseek-r1-250120 | 16.3 | 500 tokens | 9 积分 |
| 文本 | deepseek-r1-250120 | 16.3 | 1000 tokens | 17 积分 |
| 图片 | doubao-vision-pro-32k | 10.4 | 100 tokens | 2 积分 |
| 图片 | doubao-vision-pro-32k | 10.4 | 500 tokens | 6 积分 |
| 图片 | doubao-vision-pro-32k | 10.4 | 1000 tokens | 11 积分 |

## 代码实现

### 文本API计费
```javascript
const TEXT_RATE = 16.3;  // 积分/1k tokens
const cost = Math.ceil((totalTokens / 1000) * TEXT_RATE);
```

### 图片API计费
```javascript
const IMAGE_RATE = 10.4;  // 积分/1k tokens
const cost = Math.ceil((totalTokens / 1000) * IMAGE_RATE);
```

## 注意事项

1. **向上取整**: 所有费用计算都使用 `Math.ceil()` 向上取整
2. **最小扣费**: 即使只使用1个token，也会扣除至少1积分
3. **实际费率**: 由于向上取整的存在，实际费率可能略高于标称费率
   - 例如：100 tokens 按16.3费率应为1.63积分，但会扣除2积分
   - 实际费率显示为 20.00 积分/1k tokens
   - 这是正常现象，因为计费公式正确：`ceil((100/1000)*16.3) = ceil(1.63) = 2`

## 更新历史

- 2025-11-07: 初始版本
  - 文本API: 16.3 积分/1k tokens
  - 图片API: 10.4 积分/1k tokens

