# 费率调整说明文档

## 📊 调整内容

### 旧费率（65%）
- **1000 tokens = 13虫洞币**
- 12篇帖子约消耗 **110虫洞币**

### 新费率（55%）✨
- **1000 tokens = 11虫洞币**
- 12篇帖子约消耗 **93虫洞币**

### 节省效果
- **降低 15.5%** 的积分消耗
- 用户充值 ¥18（18000币）可使用更久

---

## 💰 定价对比

### 豆包API成本
- 输入：¥0.02/M tokens
- 输出：¥0.06/M tokens
- 平均：¥0.04/1000 tokens

### 虫洞币定价
- ¥18 = 18000虫洞币
- 1虫洞币 = ¥0.001

### 费率对比
| 费率 | tokens/虫洞币 | 成本(¥) | 利润率 | 用户体验 |
|------|--------------|---------|---------|----------|
| 65% | 1000/13 | ¥0.013 | 67.5% | 中等 |
| **55%** | **1000/11** | **¥0.011** | **72.5%** | **更好** ✅ |
| 45% | 1000/9 | ¥0.009 | 77.5% | 很好 |

---

## 🔄 修改内容

### 1. 回退视觉API固定积分
- ❌ 删除 `CREDITS_PER_DOUBAO_SEED_VISION`
- ❌ 删除 `CREDITS_PER_DOUBAO_VISION_PRO`
- ✅ 视觉API恢复使用统一token计费

### 2. 更新费率配置
- 文件：`production.env`
- 参数：`CREDITS_PER_1K_TOKENS=11`（从13改为11）

### 3. 代码更改
- `server.js`: 视觉API使用统一 `CREDITS_PER_1K_TOKENS`
- 文本API和视觉API使用相同费率

---

## 🚀 部署步骤

### 1. 部署更新
```bash
cd /Users/lishilong/IOS开发/虫遇/虫遇/backend
./update_rate_to_55.sh
```

### 2. 测试验证
```bash
./test_rate_55.sh
```

### 3. 预期结果
- ✅ 配置显示 `CREDITS_PER_1K_TOKENS = 11`
- ✅ 1000 tokens 消耗约11虫洞币
- ✅ 12篇帖子消耗约93虫洞币（从110降低）

---

## 📝 回滚计划

如果需要回退到65%费率：

```bash
ssh root@47.94.254.130
cd /var/www/chongyu-backend
sed -i 's/CREDITS_PER_1K_TOKENS=11/CREDITS_PER_1K_TOKENS=13/' production.env
pm2 restart chongyu-backend --update-env
```

---

## 📅 变更日期
- **创建时间**: 2025-11-02
- **生效时间**: 待部署
- **修改人**: 李世龙

