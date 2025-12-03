// 你说的"12篇帖子49币"，我们来找到这12篇
const data = require('./server-data.json');

const token = "D08B9230-99EE-43D4-88AE-4626E001776C";

// 找最新的12笔扣费
const recent12 = data.transactions
  .filter(tx => tx.type === 'debit' && tx.token === token)
  .slice(-12);

console.log('=== 你说的12篇帖子消耗49币分析 ===\n');

const totalCredits = recent12.reduce((sum, tx) => sum + tx.amount, 0);
const totalTokens = recent12.reduce((sum, tx) => sum + (tx.meta?.totalTokens || 0), 0);

console.log(`最近12次扣费总计: ${totalCredits} 虫洞币`);
console.log(`总tokens: ${totalTokens}`);
console.log(`平均每篇: ${(totalCredits/12).toFixed(2)} 币`);
console.log('');

// 看看是否有其他账户最近生成了12篇消耗49币
console.log('检查所有账户的debit记录...\n');

const allDebits = data.transactions.filter(tx => tx.type === 'debit');
const uniqueTokens = [...new Set(allDebits.map(tx => tx.token))];

uniqueTokens.forEach(t => {
  const last12 = allDebits.filter(tx => tx.token === t).slice(-12);
  if (last12.length >= 12) {
    const sum = last12.reduce((s, tx) => s + tx.amount, 0);
    if (sum >= 45 && sum <= 55) {  // 接近49
      const tkns = last12.reduce((s, tx) => s + (tx.meta?.totalTokens || 0), 0);
      const rate = ((sum * 1000) / tkns).toFixed(2);
      console.log(`账户 ${t.substring(0, 20)}...`);
      console.log(`  12篇消耗: ${sum} 币, ${tkns} tokens, 费率≈${rate}`);
    }
  }
});
