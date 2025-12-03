#!/bin/bash
# 检查余额265936的账户在远程服务器上的交易记录

echo "=== 从远程服务器查询账户 265936 的数据 ==="
echo ""

# 尝试两个服务器地址
for SERVER in "121.40.184.29:3000" "47.94.254.130:3000"; do
  echo "📡 尝试连接: $SERVER"
  
  # 通过API查询测试（需要有API端点）
  HEALTH=$(curl -s --connect-timeout 3 "http://$SERVER/health" 2>/dev/null)
  
  if [ $? -eq 0 ] && [ "$HEALTH" = '{"ok":true}' ]; then
    echo "✅ 服务器在线"
    echo ""
    
    # 直接SSH到服务器查询数据
    SERVER_IP=$(echo $SERVER | cut -d: -f1)
    echo "🔍 正在查询账户数据..."
    
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "root@$SERVER_IP" << 'REMOTE'
cd /var/www/chongyu-backend 2>/dev/null || cd /root/chongyu-backend 2>/dev/null || cd ~

if [ -f server-data.json ]; then
  echo "✅ 找到数据文件"
  node -e "
  const fs = require('fs');
  const data = JSON.parse(fs.readFileSync('server-data.json', 'utf8'));
  
  // 找余额265936的账户
  const wallet = Object.entries(data.wallets).find(([token, w]) => w.balance === 265936);
  
  if (wallet) {
    const [appAccountToken, walletData] = wallet;
    console.log('\n✅ 找到账户！');
    console.log('AppAccountToken:', appAccountToken.slice(0, 30) + '...');
    console.log('当前余额:', walletData.balance, 'credits');
    console.log('');
    
    // 今天的交易
    const today = new Date().toISOString().split('T')[0];
    const todayTxs = data.transactions
      .filter(tx => tx.appAccountToken === appAccountToken && tx.at.startsWith(today))
      .sort((a, b) => new Date(a.at) - new Date(b.at));
    
    console.log('=== 今天(11月7日)的交易 ===');
    todayTxs.forEach(tx => {
      const time = new Date(tx.at).toLocaleTimeString('zh-CN', {hour12: false});
      const sign = tx.type === 'credit' ? '+' : '-';
      const tokens = tx.meta?.totalTokens ? ' (' + tx.meta.totalTokens + 'T)' : '';
      console.log('[' + time + '] ' + sign + tx.amount + '币' + tokens + ' - ' + (tx.reason || ''));
    });
    
    const spent = todayTxs.filter(tx => tx.type === 'debit').reduce((s, tx) => s + tx.amount, 0);
    console.log('\n今天总支出:', spent, 'credits');
    
  } else {
    console.log('❌ 未找到余额265936的账户');
  }
  "
elif [ -f data.json ]; then
  echo "✅ 找到data.json"
  # 同样的逻辑...
else
  echo "❌ 未找到数据文件"
fi
REMOTE
    
    if [ $? -eq 0 ]; then
      echo ""
      echo "✅ 查询完成"
      break
    fi
  else
    echo "❌ 服务器离线或无响应"
  fi
  echo ""
done

