# 视觉API积分扣除测试说明

## 方法1：使用测试脚本（推荐）

1. 将 `test_vision_credits.sh` 上传到服务器：
```bash
# 在本地执行
scp backend/test_vision_credits.sh root@172.24.42.243:/var/www/chongyu-backend/
```

2. 在服务器上运行测试：
```bash
# SSH登录服务器
ssh root@172.24.42.243
# 密码: 3Qq123456.

# 进入项目目录
cd /var/www/chongyu-backend

# 运行测试脚本
bash test_vision_credits.sh
```

## 方法2：手动测试步骤

### 步骤1：SSH登录服务器
```bash
ssh root@172.24.42.243
# 密码: 3Qq123456.
cd /var/www/chongyu-backend
```

### 步骤2：检查环境配置
```bash
grep 'CREDITS_PER_.*_VISION' production.env
```
预期输出：
```
CREDITS_PER_DOUBAO_SEED_VISION=10
CREDITS_PER_DOUBAO_VISION_PRO=20
```

### 步骤3：创建测试账户
```bash
curl -X POST http://localhost:3000/api/wallet/init \
  -H 'Content-Type: application/json' \
  -d '{"appAccountToken":"vision-test-manual"}'
```

### 步骤4：充值5000积分
```bash
curl -X POST http://localhost:3000/api/wallet/balance \
  -H 'Content-Type: application/json' \
  -d '{"appAccountToken":"vision-test-manual","amount":5000}'
```
预期输出：`{"balance":5000}`

### 步骤5：调用视觉API (doubao-seed模型)
```bash
curl -X POST http://localhost:3000/api/vision \
  -H 'Content-Type: application/json' \
  -H 'X-App-Account-Token: vision-test-manual' \
  -d '{"model":"doubao-seed-1-6-vision-250815","messages":[{"role":"user","content":"你好"}],"max_tokens":50}'
```
这应该扣除10积分

### 步骤6：查看剩余积分
```bash
curl http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-manual
```
预期输出：`{"balance":4990}` ✓

### 步骤7：调用视觉API (doubao-vision-pro模型)
```bash
curl -X POST http://localhost:3000/api/vision \
  -H 'Content-Type: application/json' \
  -H 'X-App-Account-Token: vision-test-manual' \
  -d '{"model":"doubao-vision-pro-32k","messages":[{"role":"user","content":"你好"}],"max_tokens":20}'
```
这应该扣除20积分

### 步骤8：查看最终积分
```bash
curl http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-manual
```
预期输出：`{"balance":4970}` ✓

## 预期结果

- 初始积分：5000
- 调用doubao-seed-vision后：4990（扣除10积分）✓
- 调用doubao-vision-pro后：4970（扣除20积分）✓

## 如果测试失败

1. 检查服务器日志：
```bash
pm2 logs chongyu-api --lines 50
```

2. 检查环境变量是否正确设置：
```bash
cat production.env | grep VISION
```

3. 重启服务：
```bash
pm2 restart chongyu-api
```

## 一键复制测试命令

```bash
# 完整测试流程（可以一次性粘贴）
cd /var/www/chongyu-backend && \
echo "1. 环境配置:" && \
grep 'CREDITS_PER_.*_VISION' production.env && \
echo -e "\n2. 创建账户:" && \
curl -s -X POST http://localhost:3000/api/wallet/init -H 'Content-Type: application/json' -d '{"appAccountToken":"vt-001"}' && \
echo -e "\n\n3. 充值5000:" && \
curl -s -X POST http://localhost:3000/api/wallet/balance -H 'Content-Type: application/json' -d '{"appAccountToken":"vt-001","amount":5000}' && \
echo -e "\n\n4. 调用seed模型:" && \
curl -s -X POST http://localhost:3000/api/vision -H 'Content-Type: application/json' -H 'X-App-Account-Token: vt-001' -d '{"model":"doubao-seed-1-6-vision-250815","messages":[{"role":"user","content":"你好"}],"max_tokens":10}' && \
sleep 1 && \
echo -e "\n\n5. 查看积分(应为4990):" && \
curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vt-001 && \
echo -e "\n\n6. 调用pro模型:" && \
curl -s -X POST http://localhost:3000/api/vision -H 'Content-Type: application/json' -H 'X-App-Account-Token: vt-001' -d '{"model":"doubao-vision-pro-32k","messages":[{"role":"user","content":"你好"}],"max_tokens":10}' && \
sleep 1 && \
echo -e "\n\n7. 查看积分(应为4970):" && \
curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vt-001 && \
echo -e "\n\n测试完成！"
```

