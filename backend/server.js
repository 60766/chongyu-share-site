const express = require('express')
const cors = require('cors')
const morgan = require('morgan')
const axios = require('axios')
const crypto = require('crypto')
const dotenv = require('dotenv')
const { createRemoteJWKSet, jwtVerify } = require('jose')
const fs = require('fs')
const path = require('path')

// Simple nanoid replacement for Node.js 16 compatibility
function nanoid(size = 21) {
  const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
  let result = ''
  for (let i = 0; i < size; i++) {
    result += alphabet[Math.floor(Math.random() * alphabet.length)]
  }
  return result
}

// Generate ID function for API responses
function generateId() {
  return nanoid(28)
}

dotenv.config()

const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))  // 增大限制以支持多图片上传
app.use(morgan('dev'))

// In-memory store for demo. Replace with persistent DB in production.
const wallets = new Map() // key: appAccountToken, value: { balance: number }
const transactions = []
const processedIapTransactions = new Set()
const appleIdAccounts = new Map() // key: appleUserId, value: { appAccountToken: string, linkedAt: number }
const backupCodeMap = new Map() // key: backupCode, value: appAccountToken

// --- File persistence (lightweight) ---
const DATA_FILE = process.env.DATA_FILE || path.resolve(process.cwd(), 'server-data.json')
let saveTimer = null

function serializeState() {
  return {
    wallets: Object.fromEntries(Array.from(wallets.entries()).map(([k, v]) => [k, { balance: Number(v?.balance || 0) }])),
    transactions,
    processedIapTransactions: Array.from(processedIapTransactions.values()),
    appleIdAccounts: Object.fromEntries(Array.from(appleIdAccounts.entries())),
    backupCodeMap: Object.fromEntries(Array.from(backupCodeMap.entries())),
    savedAt: Date.now(),
  }
}

function saveToDisk() {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(serializeState(), null, 2))
    // eslint-disable-next-line no-console
    console.log('[Persist] saved to', DATA_FILE)
  } catch (err) {
    console.error('[Persist] save failed:', err?.message || err)
  } finally {
    saveTimer = null
  }
}

function scheduleSave() {
  if (saveTimer) return
  saveTimer = setTimeout(saveToDisk, 500)
}

function loadFromDisk() {
  try {
    if (!fs.existsSync(DATA_FILE)) return
    const raw = fs.readFileSync(DATA_FILE, 'utf8')
    if (!raw) return
    const json = JSON.parse(raw)
    // wallets
    if (json?.wallets && typeof json.wallets === 'object') {
      Object.entries(json.wallets).forEach(([token, w]) => {
        wallets.set(token, { balance: Number(w?.balance || 0) })
      })
    }
    // transactions
    if (Array.isArray(json?.transactions)) {
      transactions.splice(0, transactions.length, ...json.transactions)
    }
    // processed set
    if (Array.isArray(json?.processedIapTransactions)) {
      processedIapTransactions.clear()
      json.processedIapTransactions.forEach(id => processedIapTransactions.add(String(id)))
    }
    // apple accounts
    if (json?.appleIdAccounts && typeof json.appleIdAccounts === 'object') {
      appleIdAccounts.clear()
      Object.entries(json.appleIdAccounts).forEach(([appleUserId, v]) => {
        if (v && typeof v === 'object') {
          appleIdAccounts.set(appleUserId, {
            appAccountToken: v.appAccountToken,
            displayName: v.displayName,
            email: v.email,
            linkedAt: Number(v.linkedAt || Date.now()),
          })
        }
      })
    }
    // backup code map
    if (json?.backupCodeMap && typeof json.backupCodeMap === 'object') {
      backupCodeMap.clear()
      Object.entries(json.backupCodeMap).forEach(([code, token]) => {
        backupCodeMap.set(code, token)
      })
    }
    console.log('[Persist] loaded from', DATA_FILE)
  } catch (err) {
    console.error('[Persist] load failed:', err?.message || err)
  }
}

loadFromDisk()
setInterval(() => {
  try { saveToDisk() } catch {}
}, 30_000)
process.on('SIGINT', () => { try { saveToDisk() } catch {} process.exit() })
process.on('SIGTERM', () => { try { saveToDisk() } catch {} process.exit() })

const CREDITS_PER_1K_TOKENS = Number(process.env.CREDITS_PER_1K_TOKENS || 100) // example: 100 credits / 1k tokens
const PROVIDER_ENDPOINT = process.env.PROVIDER_ENDPOINT || 'https://ark.cn-beijing.volces.com/api/v3/chat/completions'
const PROVIDER_MODEL = process.env.PROVIDER_MODEL || 'deepseek-r1-250120'
const PROVIDER_API_KEY = process.env.PROVIDER_API_KEY || 'demo_key_placeholder'

// Apple Sign In config
const APPLE_ISSUER = 'https://appleid.apple.com'
const APP_BUNDLE_ID = process.env.APP_BUNDLE_ID || 'YOUR_IOS_BUNDLE_ID' // e.g. com.example.app
const APPLE_JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'))

// Debug configuration (does not print the actual key)
console.log('[Config] PROVIDER_ENDPOINT:', PROVIDER_ENDPOINT)
console.log('[Config] PROVIDER_MODEL:', PROVIDER_MODEL)
console.log('[Config] MOCK_PROVIDER:', process.env.MOCK_PROVIDER || 'not set')
console.log('[Config] API key provided:', PROVIDER_API_KEY && PROVIDER_API_KEY !== 'demo_key_placeholder' ? 'yes' : 'no')
console.log('[Config] APP_BUNDLE_ID:', APP_BUNDLE_ID)

async function verifyAppleIdentityToken(identityToken, expectedSub) {
  try {
    const { payload } = await jwtVerify(identityToken, APPLE_JWKS, {
      issuer: APPLE_ISSUER,
      audience: APP_BUNDLE_ID,
    })
    if (expectedSub && payload.sub !== expectedSub) {
      throw new Error('sub_mismatch')
    }
    return payload
  } catch (err) {
    const reason = err?.message || 'verify_failed'
    const e = new Error('apple_identity_token_invalid')
    e.reason = reason
    throw e
  }
}

function getWallet(token) {
  if (!wallets.has(token)) wallets.set(token, { balance: 0 })
  return wallets.get(token)
}

function debitWallet(token, amount, ref, meta = {}) {
  const wallet = getWallet(token)
  wallet.balance = Math.max(0, wallet.balance - amount)
  transactions.push({ id: nanoid(), type: 'debit', token, amount, ref, meta, at: Date.now() })
  scheduleSave()
  return wallet.balance
}

function creditWallet(token, amount, ref, meta = {}) {
  const wallet = getWallet(token)
  wallet.balance += amount
  transactions.push({ id: nanoid(), type: 'topup', token, amount, ref, meta, at: Date.now() })
  scheduleSave()
  return wallet.balance
}

app.get('/health', (_, res) => res.json({ ok: true }))

app.get('/balance', (req, res) => {
  const appAccountToken = req.header('X-App-Account-Token') || req.query.appAccountToken
  console.log('[BALANCE] Request from token:', appAccountToken ? `${appAccountToken.substring(0, 8)}...` : 'MISSING')
  if (!appAccountToken) return res.status(400).json({ error: 'missing appAccountToken' })
  const wallet = getWallet(appAccountToken)
  console.log('[BALANCE] Current balance for token:', wallet.balance)
  res.json({ balance: wallet.balance, currency: 'CREDITS' })
})

app.post('/purchase/confirm', (req, res) => {
  const appAccountToken = req.body?.appAccountToken || req.header('X-App-Account-Token') || req.query.appAccountToken
  const { productId, transactionId, receipt } = req.body || {}
  // Debug log
  console.log('[IAP] confirm payload', { appAccountToken, productId, transactionId, hasReceipt: Boolean(receipt) })
  if (!appAccountToken || !productId || !transactionId) return res.status(400).json({ error: 'missing params', got: { appAccountToken: !!appAccountToken, productId: !!productId, transactionId: !!transactionId } })

  // TODO: verify with App Store Server API using receipt. For MVP, accept and credit by SKU table.
  // 支持两种Product ID格式：
  // 1. 旧格式：credits.small, credits.medium, 等
  // 2. 新格式（带Bundle ID）：com.lishilong.chongyu.100energy, 等
  const skuToCredits = {
    // 旧格式（向后兼容）
    'credits.small': 1800,      // ¥6 入门包
    'credits.medium': 6000,     // ¥18 标准包
    'credits.large': 13800,     // ¥38 豪华包
    'credits.xlarge': 26800,    // ¥68 至尊包
    // 新格式（生产环境Bundle ID）
    'com.lishilong.chongyu.100energy': 1800,   // ¥6 = 100能量
    'com.lishilong.chongyu.300energy': 6000,   // ¥18 = 300能量
    'com.lishilong.chongyu.700energy': 13800,  // ¥38 = 700能量
    'com.lishilong.chongyu.1400energy': 26800, // ¥68 = 1400能量
  }
  const credits = skuToCredits[productId]
  if (!credits) return res.status(400).json({ error: 'unknown productId', productId, supported: Object.keys(skuToCredits) })

  // Idempotency: prevent duplicate credits for the same transactionId
  if (processedIapTransactions.has(transactionId)) {
    const wallet = getWallet(appAccountToken)
    return res.json({ balance: wallet.balance, currency: 'CREDITS' })
  }

  // Optional: keep parsed receipt fields for audit
  let parsedReceipt = null
  try { if (typeof receipt === 'string' && receipt.length) parsedReceipt = JSON.parse(receipt) } catch {}

  const balanceAfter = creditWallet(appAccountToken, credits, transactionId, { productId, receipt: parsedReceipt || receipt })
  processedIapTransactions.add(transactionId)
  scheduleSave()
  res.json({ balance: balanceAfter, currency: 'CREDITS' })
})

// Apple ID 账号关联
app.post('/account/link-apple', async (req, res) => {
  const appAccountToken = req.body?.appAccountToken || req.header('X-App-Account-Token')
  const { appleUserId, displayName, email, identityToken } = req.body || {}
  
  console.log('[Apple ID] 关联请求', { appAccountToken: !!appAccountToken, appleUserId: !!appleUserId, hasToken: Boolean(identityToken) })
  
  if (!appAccountToken || !appleUserId || !identityToken) {
    return res.status(400).json({ error: 'missing params', got: { appAccountToken: !!appAccountToken, appleUserId: !!appleUserId, identityToken: !!identityToken } })
  }

  // 验证 Apple 身份令牌（签名 + iss/aud/sub）
  try {
    const payload = await verifyAppleIdentityToken(identityToken, appleUserId)
    // 可选：仅首次登录时可能包含 email
    const verifiedEmail = payload.email || email

    // 检查Apple ID是否已经关联其他账号
    if (appleIdAccounts.has(appleUserId)) {
      const existing = appleIdAccounts.get(appleUserId)
      if (existing.appAccountToken !== appAccountToken) {
        return res.status(409).json({ error: 'apple_id_already_linked', existingToken: existing.appAccountToken })
      }
    }

    // 关联Apple ID与应用账号
    appleIdAccounts.set(appleUserId, {
      appAccountToken,
      displayName,
      email: verifiedEmail,
      linkedAt: Date.now()
    })

    scheduleSave()
    res.json({ success: true, linkedAt: Date.now() })
  } catch (err) {
    return res.status(401).json({ error: 'apple_identity_token_invalid', reason: err?.reason || err?.message || 'verify_failed' })
  }
})

// Apple ID 账号解绑
app.post('/account/unlink-apple', (req, res) => {
  const appAccountToken = req.body?.appAccountToken || req.header('X-App-Account-Token')
  const { appleUserId } = req.body || {}
  
  if (!appAccountToken || !appleUserId) {
    return res.status(400).json({ error: 'missing params' })
  }
  
  // 验证Apple ID确实关联了这个账号
  const existing = appleIdAccounts.get(appleUserId)
  if (!existing || existing.appAccountToken !== appAccountToken) {
    return res.status(404).json({ error: 'apple_id_not_linked' })
  }
  
  // 解绑Apple ID
  appleIdAccounts.delete(appleUserId)
  scheduleSave()
  
  res.json({ success: true, unlinkedAt: Date.now() })
})

// 通过Apple ID查找账号（可选，不强制校验token）
app.post('/account/find-by-apple', (req, res) => {
  const { appleUserId } = req.body || {}
  
  if (!appleUserId) {
    return res.status(400).json({ error: 'missing appleUserId' })
  }
  
  const account = appleIdAccounts.get(appleUserId)
  if (!account) {
    return res.status(404).json({ error: 'apple_id_not_found' })
  }
  
  res.json({
    appAccountToken: account.appAccountToken,
    linkedAt: account.linkedAt,
    displayName: account.displayName,
    email: account.email
  })
})

// 注册备份码映射（备份码 -> appAccountToken）
app.post('/account/register-backup', (req, res) => {
  const appAccountToken = req.body?.appAccountToken || req.header('X-App-Account-Token')
  const { backupCode } = req.body || {}
  if (!appAccountToken || !backupCode) {
    return res.status(400).json({ error: 'missing params' })
  }
  // 为了安全，覆盖同一备份码的旧映射
  backupCodeMap.set(backupCode, appAccountToken)
  scheduleSave()
  res.json({ success: true })
})

// 通过备份码恢复账号
app.post('/account/restore-by-backup', (req, res) => {
  const { backupCode } = req.body || {}
  if (!backupCode) {
    return res.status(400).json({ error: 'missing backupCode' })
  }
  const token = backupCodeMap.get(backupCode)
  if (!token) {
    return res.status(404).json({ error: 'backup_code_not_found' })
  }
  res.json({ appAccountToken: token })
})

app.post('/api/proxy', async (req, res) => {
  const appAccountToken = req.header('X-App-Account-Token') || req.body.appAccountToken
  if (!appAccountToken) return res.status(400).json({ error: 'missing appAccountToken' })

  const wallet = getWallet(appAccountToken)
  if (wallet.balance <= 0) return res.status(402).json({ error: 'insufficient_credits', balance: wallet.balance })

  const { model, messages, stream, ...rest } = req.body || {}
  const payload = {
    model: model || PROVIDER_MODEL,
    messages,
    stream: Boolean(stream),
    ...rest,
  }

  try {
    // MOCK provider support for local testing without a real key
    const useMock = process.env.MOCK_PROVIDER === '1' || !PROVIDER_API_KEY || PROVIDER_API_KEY === 'demo_key_placeholder'
    let data
    if (useMock) {
      const lastUser = Array.isArray(messages) ? messages[messages.length - 1]?.content : ''
      data = {
        id: generateId(),
        choices: [
          { message: { role: 'assistant', content: `这是模拟回答：${lastUser || 'Hello'}` } }
        ],
        usage: { total_tokens: 400, input_tokens: 200, output_tokens: 200 }
      }
    } else {
      const providerResp = await axios.post(PROVIDER_ENDPOINT, payload, {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${PROVIDER_API_KEY}`,
        },
        timeout: 300_000,
        maxContentLength: Infinity,
        maxBodyLength: Infinity,
      })
      data = providerResp.data
    }

    // Estimate usage/tokens
    let totalTokens = 0
    if (data?.usage?.total_tokens != null) {
      totalTokens = Number(data.usage.total_tokens)
    } else if (data?.usage?.input_tokens != null || data?.usage?.output_tokens != null) {
      totalTokens = Number(data.usage.input_tokens || 0) + Number(data.usage.output_tokens || 0)
    } else {
      // fallback rough estimate
      totalTokens = 800
    }

    const costCredits = Math.ceil((totalTokens / 1000) * CREDITS_PER_1K_TOKENS)

    if (wallet.balance < costCredits) {
      return res.status(402).json({ error: 'insufficient_credits', needed: costCredits, balance: wallet.balance })
    }

    const balanceAfter = debitWallet(appAccountToken, costCredits, generateId(), { totalTokens, providerModel: payload.model })

    res.setHeader('X-Usage-Tokens', String(totalTokens))
    res.setHeader('X-Cost-Credits', String(costCredits))
    res.setHeader('X-Balance-After', String(balanceAfter))
    
    // Smart response transmission: use chunked transfer for large responses
    const responseStr = JSON.stringify(data)
    const responseSize = Buffer.byteLength(responseStr, 'utf8')
    
    console.log(`[Response] Size: ${responseSize} bytes, will use ${responseSize > 2000 ? 'chunked' : 'standard'} transfer`)
    
    if (responseSize > 2000) {
      // Large response: use chunked transfer encoding with smaller threshold
      res.setHeader('Transfer-Encoding', 'chunked')
      res.setHeader('Content-Type', 'application/json')
      res.setHeader('Cache-Control', 'no-cache')
      
      // 分多个小块发送，每块最大1000字节
      const chunkSize = 1000
      for (let i = 0; i < responseStr.length; i += chunkSize) {
        const chunk = responseStr.slice(i, i + chunkSize)
        res.write(chunk)
        // 小延迟确保数据完整传输
        await new Promise(resolve => setTimeout(resolve, 10))
      }
      res.end()
    } else {
      // Small response: use standard JSON response
      res.json(data)
    }
  } catch (err) {
    const status = err.response?.status || 500
    const body = err.response?.data || { error: 'provider_error', message: err.message }
    res.status(status).json(body)
  }
})

// 豆包视觉API代理端点
app.post('/api/vision', async (req, res) => {
  const appAccountToken = req.header('X-App-Account-Token') || req.body.appAccountToken
  if (!appAccountToken) return res.status(400).json({ error: 'missing appAccountToken' })

  const wallet = getWallet(appAccountToken)
  if (wallet.balance <= 0) return res.status(402).json({ error: 'insufficient_credits', balance: wallet.balance })

  const { model, messages, max_tokens, temperature, ...rest } = req.body || {}
  
  // 计算请求中的图片数量（用于调试）
  let imageCount = 0
  if (Array.isArray(messages)) {
    messages.forEach(msg => {
      if (Array.isArray(msg.content)) {
        imageCount += msg.content.filter(item => item.type === 'image_url').length
      }
    })
  }
  
  // 计算请求体大小
  const requestBodySize = JSON.stringify(req.body).length
  console.log(`[Vision API] 📊 请求统计: ${imageCount}张图片, 请求体大小: ${(requestBodySize / 1024 / 1024).toFixed(2)}MB`)
  
  // 豆包视觉API配置
  const DOUBAO_VISION_ENDPOINT = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions'
  const DOUBAO_API_KEY = process.env.DOUBAO_API_KEY || '5ec25df2-f799-4fc0-8ee2-ac13d473131b'
  const DOUBAO_MODEL = model || 'doubao-seed-1-6-vision-250815'

  const payload = {
    model: DOUBAO_MODEL,
    messages,
    max_tokens: max_tokens || 1000,
    temperature: temperature || 0.3,
    ...rest,
  }

  try {
    console.log('[Vision API] 🚀 调用豆包视觉API')
    const startTime = Date.now()
    
    const visionResp = await axios.post(DOUBAO_VISION_ENDPOINT, payload, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${DOUBAO_API_KEY}`,
      },
      timeout: 120_000, // 120秒超时
      maxContentLength: Infinity,
      maxBodyLength: Infinity,
    })

    const data = visionResp.data

    // 估算token使用量（视觉API通常消耗更多token）
    let totalTokens = 0
    if (data?.usage?.total_tokens != null) {
      totalTokens = Number(data.usage.total_tokens)
    } else if (data?.usage?.input_tokens != null || data?.usage?.output_tokens != null) {
      totalTokens = Number(data.usage.input_tokens || 0) + Number(data.usage.output_tokens || 0)
    } else {
      // 视觉API的fallback估算（通常比文本API消耗更多）
      totalTokens = 1500
    }

    // 视觉API成本更高，使用2倍费率
    const costCredits = Math.ceil((totalTokens / 1000) * CREDITS_PER_1K_TOKENS * 2)

    if (wallet.balance < costCredits) {
      return res.status(402).json({ error: 'insufficient_credits', needed: costCredits, balance: wallet.balance })
    }

    const balanceAfter = debitWallet(appAccountToken, costCredits, generateId(), { 
      totalTokens, 
      providerModel: payload.model,
      apiType: 'vision'
    })

    const elapsedTime = Date.now() - startTime
    
    res.setHeader('X-Usage-Tokens', String(totalTokens))
    res.setHeader('X-Cost-Credits', String(costCredits))
    res.setHeader('X-Balance-After', String(balanceAfter))
    
    console.log(`[Vision API] ✅ 成功处理 (${elapsedTime}ms)，消耗${costCredits}积分，剩余${balanceAfter}积分`)
    res.json(data)
    
  } catch (err) {
    const elapsedTime = Date.now() - startTime
    console.error(`[Vision API] ❌ 错误 (${elapsedTime}ms):`, err.message)
    
    // 详细错误日志
    if (err.response) {
      console.error(`[Vision API] 豆包API响应状态: ${err.response.status}`)
      console.error(`[Vision API] 豆包API错误详情:`, JSON.stringify(err.response.data, null, 2))
    } else if (err.request) {
      console.error(`[Vision API] 请求发送但没有收到响应`)
    } else {
      console.error(`[Vision API] 请求配置错误:`, err.message)
    }
    
    const status = err.response?.status || 500
    const body = err.response?.data || { error: 'vision_api_error', message: err.message }
    res.status(status).json(body)
  }
})

const port = process.env.PORT || 8787
const server = app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`)
}) 
// Extend HTTP server timeouts to allow long-running AI requests
server.headersTimeout = 305_000
server.requestTimeout = 305_000
server.keepAliveTimeout = 120_000 