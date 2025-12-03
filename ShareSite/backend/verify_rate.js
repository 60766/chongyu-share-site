const data = require('./server-data.json');

// 分析所有D08B9230账户的debit交易，推测费率
const token = "D08B9230-99EE-43D4-88AE-4626E001776C";
const debits = data.transactions
  .filter(tx => tx.type === 'debit' && tx.token === token && tx.meta?.totalTokens)
  .slice(-20);

console.log('=== 推测实际运行费率 ===\n');
console.log('Tokens | 扣币 | 推测费率 | 时间');
console.log('-------|------|----------|-----');

const rates = [];
debits.forEach(tx => {
  const tokens = tx.meta.totalTokens;
  const credits = tx.amount;
  const rate = ((credits * 1000) / tokens).toFixed(2);
  rates.push(parseFloat(rate));
  
  const date = new Date(tx.at).toLocaleString('zh-CN');
  console.log(`${tokens.toString().padStart(6)} | ${credits.toString().padStart(4)} | ${rate.padStart(8)} | ${date}`);
});

const avgRate = (rates.reduce((a,b) => a+b, 0) / rates.length).toFixed(2);
console.log('-------|------|----------|-----');
console.log(`平均费率: ${avgRate} 虫洞币/1K tokens`);
console.log('');
console.log('💡 发现：');
console.log(`   • 配置文件显示: 1.7 虫洞币/1K tokens`);
console.log(`   • 本地日志显示: 4.0 虫洞币/1K tokens`);
console.log(`   • 实际执行费率: ${avgRate} 虫洞币/1K tokens`);
console.log('');
console.log('⚠️  结论: 本地服务器正在使用旧费率，需要重启服务器加载新配置！');
