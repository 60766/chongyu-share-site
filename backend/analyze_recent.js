const data = require('./server-data.json');

// 找到账户 D08B9230 的最近12次debit交易
const token = "D08B9230-99EE-43D4-88AE-4626E001776C";
const debits = data.transactions
  .filter(tx => tx.type === 'debit' && tx.token === token)
  .slice(-12);  // 最近12条

console.log('=== 最近12次帖子生成的消耗明细 ===\n');
console.log('序号 | Tokens  | 扣币 | 计算验证');
console.log('-----|---------|------|----------');

let totalTokens = 0;
let totalCredits = 0;

debits.forEach((tx, idx) => {
  const tokens = tx.meta?.totalTokens || 0;
  const credits = tx.amount;
  const calculated = Math.ceil((tokens / 1000) * 1.7);
  const match = calculated === credits ? '✓' : `✗ (应为${calculated})`;
  
  totalTokens += tokens;
  totalCredits += credits;
  
  console.log(`${(idx+1).toString().padStart(4)} | ${tokens.toString().padStart(7)} | ${credits.toString().padStart(4)} | ${match}`);
});

console.log('-----|---------|------|----------');
console.log(`总计 | ${totalTokens.toString().padStart(7)} | ${totalCredits.toString().padStart(4)} |`);
console.log('');
console.log('=== 验证结果 ===');
console.log(`实际扣币总计: ${totalCredits} 虫洞币`);
console.log(`平均每篇消耗: ${(totalCredits/12).toFixed(2)} 虫洞币`);
console.log(`平均每篇tokens: ${Math.round(totalTokens/12)} tokens`);
console.log(`当前费率: 1.7 虫洞币/1K tokens`);
console.log(`理论扣币: ceil(${totalTokens}/1000 × 1.7) = ${Math.ceil((totalTokens/1000)*1.7)} 虫洞币`);
console.log('');

if (totalCredits === Math.ceil((totalTokens/1000)*1.7)) {
  console.log('✅ 扣币完全准确！符合1.7费率');
} else {
  console.log(`⚠️  扣币有差异，差值: ${totalCredits - Math.ceil((totalTokens/1000)*1.7)}`);
}
