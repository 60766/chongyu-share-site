# API费率验证总结

## ✅ 验证完成

所有API费率已经过验证并正确设置！

## 当前费率配置

### 文本API (deepseek-r1-250120)
- **费率**: 16.3 积分/1k tokens
- **验证脚本**: `./verify-rate.sh`
- **验证结果**: ✅ 通过

### 图片API (doubao-vision-pro-32k)
- **费率**: 10.4 积分/1k tokens
- **验证脚本**: `./verify-image-rate.sh`
- **验证结果**: ✅ 通过

## 快速开始

### 1. 启动服务器
```bash
cd backend
node server.js
```

### 2. 验证费率
```bash
# 验证文本API
./verify-rate.sh

# 验证图片API
./verify-image-rate.sh
```

## 计费公式

```javascript
// 文本API
const TEXT_RATE = 16.3;
const cost = Math.ceil((totalTokens / 1000) * TEXT_RATE);

// 图片API
const IMAGE_RATE = 10.4;
const cost = Math.ceil((totalTokens / 1000) * IMAGE_RATE);
```

## 关键点

1. **向上取整**: 使用 `Math.ceil()` 确保最小扣费为1积分
2. **实际费率可能更高**: 由于向上取整，小用量的实际费率会显示更高
   - 例如：72 tokens × 16.3 = 1.17 → 向上取整为 2 积分
   - 实际费率显示：(2 × 1000) / 72 = 27.78 积分/1k tokens
   - 这是正常的！计费公式是正确的
3. **默认余额**: 新用户1800积分

## 测试示例

### 文本API测试
```bash
curl http://localhost:3000/api/proxy \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: test-user" \
  -d '{
    "model":"deepseek-r1-250120",
    "messages":[{"role":"user","content":"Hi"}],
    "stream":false
  }'
```

### 图片API测试
```bash
curl http://localhost:3000/api/image-proxy \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: test-user" \
  -d '{
    "model":"doubao-vision-pro-32k",
    "messages":[{
      "role":"user",
      "content":[
        {"type":"text","text":"描述这张图片"},
        {"type":"image_url","image_url":{"url":"https://example.com/test.jpg"}}
      ]
    }],
    "stream":false
  }'
```

### 查询余额
```bash
curl "http://localhost:3000/balance?appAccountToken=test-user"
```

## 故障排除

### 端口占用
```bash
# 查找占用3000端口的进程
lsof -ti :3000

# 终止进程
lsof -ti :3000 | xargs kill -9
```

### 服务器无响应
1. 检查服务器是否运行: `ps aux | grep "node server.js"`
2. 检查日志输出
3. 重启服务器

### 验证失败
1. 确保服务器正在运行
2. 检查 `server.js` 中的费率常量
3. 查看 `/tmp/verify-response.json` 或 `/tmp/verify-image-response.json` 了解详情

## 相关文件

- `server.js` - 主服务器文件，包含费率常量
- `verify-rate.sh` - 文本API费率验证脚本
- `verify-image-rate.sh` - 图片API费率验证脚本
- `BILLING_RATES.md` - 费率详细说明文档
- `server-data.json` - 持久化数据存储

## 更新日期

2025-11-07

