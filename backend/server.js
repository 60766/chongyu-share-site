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

// 加载环境配置：优先 production.env，回退到 .env
// 使用 override: true 确保 production.env 中的值覆盖系统环境变量
const productionEnvPath = path.resolve(__dirname, 'production.env')
if (fs.existsSync(productionEnvPath)) {
  dotenv.config({ path: productionEnvPath, override: true })
  console.log('[Config] Loaded production.env')
} else {
  dotenv.config({ override: true })
  console.log('[Config] Loaded .env (production.env not found)')
}

const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))  // 增大限制以支持多图片上传
app.use(morgan('dev'))

// In-memory store for demo. Replace with persistent DB in production.
const wallets = new Map() // key: appAccountToken, value: { balance: number, createdAt: number, welcome?: WelcomeMeta }
const transactions = []
const processedIapTransactions = new Set()
const appleIdAccounts = new Map() // key: appleUserId, value: { appAccountToken: string, linkedAt: number }
const backupCodeMap = new Map() // key: backupCode, value: appAccountToken
const deviceWelcomeRecords = new Map() // key: normalized deviceId, value: { firstToken, giftCount, firstGrantedAt, lastToken, lastAttemptAt }

// --- File persistence (lightweight) ---
const DATA_FILE = process.env.DATA_FILE || path.resolve(process.cwd(), 'server-data.json')
let saveTimer = null

function serializeState() {
  return {
    wallets: Object.fromEntries(
      Array.from(wallets.entries()).map(([k, v]) => [
        k,
        {
          balance: Number(v?.balance || 0),
          createdAt: v?.createdAt || Date.now(),
          welcome: v?.welcome || null,
        },
      ])
    ),
    transactions,
    processedIapTransactions: Array.from(processedIapTransactions.values()),
    appleIdAccounts: Object.fromEntries(Array.from(appleIdAccounts.entries())),
    backupCodeMap: Object.fromEntries(Array.from(backupCodeMap.entries())),
    deviceWelcomeRecords: Object.fromEntries(Array.from(deviceWelcomeRecords.entries())),
    savedAt: Date.now(),
  }
}

function saveToDisk() {
  try {
    // 使用原子写入：先写入临时文件，然后重命名，避免写入过程中崩溃导致文件损坏
    const tempFile = DATA_FILE + '.tmp'
    const data = JSON.stringify(serializeState(), null, 2)
    fs.writeFileSync(tempFile, data)
    // 原子性重命名（在大多数文件系统上是原子操作）
    fs.renameSync(tempFile, DATA_FILE)
    // eslint-disable-next-line no-console
    console.log('[Persist] saved to', DATA_FILE)
  } catch (err) {
    console.error('[Persist] save failed:', err?.message || err)
    // 如果临时文件存在，尝试清理
    try {
      const tempFile = DATA_FILE + '.tmp'
      if (fs.existsSync(tempFile)) {
        fs.unlinkSync(tempFile)
      }
    } catch (cleanupErr) {
      // 忽略清理错误
    }
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
        wallets.set(token, {
          balance: Number(w?.balance || 0),
          createdAt: w?.createdAt || Date.now(),
          welcome: w?.welcome || null,
        })
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
    if (json?.deviceWelcomeRecords && typeof json.deviceWelcomeRecords === 'object') {
      deviceWelcomeRecords.clear()
      Object.entries(json.deviceWelcomeRecords).forEach(([deviceId, record]) => {
        deviceWelcomeRecords.set(deviceId, record)
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

const CREDITS_PER_1K_TOKENS = Number(process.env.CREDITS_PER_1K_TOKENS || 1.7) // 兼容旧配置：统一费率（不再推荐使用）
// 新配置：分别设置文本与视觉的每1k tokens扣费（默认：文本8.2，视觉0.84，确保盈利）
const CREDITS_TEXT_PER_1K_TOKENS = Number(process.env.CREDITS_TEXT_PER_1K_TOKENS || 8.2)
const CREDITS_VISION_PER_1K_TOKENS = Number(process.env.CREDITS_VISION_PER_1K_TOKENS || 0.84)
const PROVIDER_ENDPOINT = process.env.PROVIDER_ENDPOINT || 'https://ark.cn-beijing.volces.com/api/v3/chat/completions'
const PROVIDER_MODEL = process.env.PROVIDER_MODEL || 'deepseek-r1-250528'
const PROVIDER_API_KEY = process.env.PROVIDER_API_KEY || 'demo_key_placeholder'
const INITIAL_WELCOME_CREDITS = Number(process.env.INITIAL_WELCOME_CREDITS || 600)
const MIN_DEVICE_ID_LENGTH = Number(process.env.MIN_DEVICE_ID_LENGTH || 16)

// 输出费率配置日志
console.log(`[Config] CREDITS_TEXT_PER_1K_TOKENS = ${CREDITS_TEXT_PER_1K_TOKENS}`)
console.log(`[Config] CREDITS_VISION_PER_1K_TOKENS = ${CREDITS_VISION_PER_1K_TOKENS}`)

// Apple Sign In config
const APPLE_ISSUER = 'https://appleid.apple.com'
const APP_BUNDLE_ID = process.env.APP_BUNDLE_ID || 'YOUR_IOS_BUNDLE_ID' // e.g. com.example.app
const APPLE_JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'))

// App Store Server API config (for IAP verification)
// StoreKit 2 transaction JWT verification uses App Store JWKS
const APP_STORE_JWKS = createRemoteJWKSet(new URL('https://api.storekit.itunes.apple.com/in-app-purchase/publicKeys'))
const APP_STORE_ISSUER = 'https://api.storekit.itunes.apple.com'

// Debug configuration (does not print the actual key)
console.log('[Config] PROVIDER_ENDPOINT:', PROVIDER_ENDPOINT)
console.log('[Config] PROVIDER_MODEL:', PROVIDER_MODEL)
console.log('[Config] MOCK_PROVIDER:', process.env.MOCK_PROVIDER || 'not set')
console.log('[Config] API key provided:', PROVIDER_API_KEY && PROVIDER_API_KEY !== 'demo_key_placeholder' ? 'yes' : 'no')
console.log('[Config] APP_BUNDLE_ID:', APP_BUNDLE_ID)
console.log('[Config] IAP_VERIFY_STRICT:', process.env.IAP_VERIFY_STRICT === '1' ? 'enabled (strict mode)' : 'disabled (compatibility mode)')

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

/**
 * 验证 App Store IAP 交易 JWT
 * @param {string} transactionJWT - StoreKit 2 交易 JWT (transaction.jsonRepresentation)
 * @param {string} expectedProductId - 期望的产品 ID
 * @param {string} expectedTransactionId - 期望的交易 ID
 * @returns {Promise<{valid: boolean, payload?: object, error?: string}>}
 */
async function verifyIAPTransaction(transactionJWT, expectedProductId, expectedTransactionId) {
  try {
    if (!transactionJWT || typeof transactionJWT !== 'string') {
      return { valid: false, error: 'missing_or_invalid_jwt' }
    }

    // 验证 JWT 签名和基本声明
    const { payload } = await jwtVerify(transactionJWT, APP_STORE_JWKS, {
      issuer: APP_STORE_ISSUER,
      audience: APP_BUNDLE_ID,
    })

    // 检查交易类型（应该是 Transaction）
    if (payload.type !== 'Transaction') {
      return { valid: false, error: 'invalid_transaction_type', payload }
    }

    // 检查产品 ID 是否匹配
    if (payload.productId !== expectedProductId) {
      console.warn(`[IAP Verify] Product ID mismatch: expected ${expectedProductId}, got ${payload.productId}`)
      return { valid: false, error: 'product_id_mismatch', payload }
    }

    // 检查交易 ID 是否匹配
    // StoreKit 2 JWT 中，交易 ID 可能在多个字段中：
    // - transactionId: 当前交易的 ID（数字）
    // - originalTransactionId: 原始交易的 ID（如果是续订）
    // - jti: JWT ID（通常是交易 ID 的字符串形式）
    const jwtTransactionId = String(
      payload.transactionId || 
      payload.originalTransactionId || 
      payload.jti || 
      ''
    )
    
    // 尝试匹配交易 ID（支持数字和字符串格式）
    const expectedIdStr = String(expectedTransactionId)
    const expectedIdNum = Number(expectedTransactionId)
    const jwtIdStr = String(jwtTransactionId)
    const jwtIdNum = Number(jwtTransactionId)
    
    const idMatches = (
      jwtIdStr === expectedIdStr || 
      jwtIdNum === expectedIdNum ||
      String(jwtIdNum) === expectedIdStr ||
      String(expectedIdNum) === jwtIdStr
    )
    
    if (!idMatches && jwtTransactionId) {
      console.warn(`[IAP Verify] Transaction ID mismatch: expected ${expectedTransactionId}, got ${jwtTransactionId}`, {
        expectedStr: expectedIdStr,
        expectedNum: expectedIdNum,
        jwtStr: jwtIdStr,
        jwtNum: jwtIdNum,
        payloadKeys: Object.keys(payload)
      })
      return { valid: false, error: 'transaction_id_mismatch', payload, expected: expectedTransactionId, got: jwtTransactionId }
    }
    
    // 如果没有找到交易 ID，记录警告但继续（某些情况下可能正常）
    if (!jwtTransactionId) {
      console.warn('[IAP Verify] ⚠️ 未在 JWT 中找到交易 ID，但继续验证', {
        payloadKeys: Object.keys(payload),
        productId: payload.productId
      })
    }

    // 检查交易状态
    // StoreKit 2 JWT 中，revocationDate 存在表示已退款
    if (payload.revocationDate) {
      return { valid: false, error: 'transaction_revoked', payload, revokedAt: payload.revocationDate }
    }

    // 检查过期时间（如果存在）
    const now = Math.floor(Date.now() / 1000)
    if (payload.exp && payload.exp < now) {
      return { valid: false, error: 'transaction_expired', payload }
    }

    // 验证通过
    return { valid: true, payload }
  } catch (err) {
    const reason = err?.message || 'verify_failed'
    console.error('[IAP Verify] JWT verification failed:', reason)
    return { valid: false, error: 'jwt_verification_failed', reason }
  }
}

function normalizeDeviceId(deviceId) {
  if (!deviceId || typeof deviceId !== 'string') return ''
  return deviceId.trim().toLowerCase()
}

function evaluateWelcomeEligibility(deviceId, token) {
  const normalized = normalizeDeviceId(deviceId)
  if (!normalized || normalized.length < MIN_DEVICE_ID_LENGTH) {
    return { allowed: false, reason: 'missing_or_invalid_device', deviceId: normalized }
  }
  const record = deviceWelcomeRecords.get(normalized)
  if (!record) {
    deviceWelcomeRecords.set(normalized, {
      firstToken: token,
      giftCount: 1,
      firstGrantedAt: Date.now(),
    })
    scheduleSave()
    return { allowed: true, reason: 'first_device_grant', deviceId: normalized }
  }
  record.giftCount = (record.giftCount || 1) + 1
  record.lastToken = token
  record.lastAttemptAt = Date.now()
  scheduleSave()
  return { allowed: false, reason: 'device_already_granted', deviceId: normalized }
}

function getWallet(token, options = {}) {
  const { deviceId = null, allowWelcome = true } = options
  if (!wallets.has(token)) {
    let initialCredits = 0
    let welcomeMeta = { granted: false, reason: 'not_attempted' }
    if (allowWelcome) {
      const eligibility = evaluateWelcomeEligibility(deviceId, token)
      if (eligibility.allowed) {
        initialCredits = INITIAL_WELCOME_CREDITS
        welcomeMeta = {
          granted: true,
          reason: eligibility.reason,
          deviceId: eligibility.deviceId,
          grantedAt: Date.now(),
        }
      } else {
        welcomeMeta = {
          granted: false,
          reason: eligibility.reason,
          deviceId: eligibility.deviceId,
        }
      }
    }
    wallets.set(token, {
      balance: initialCredits,
      createdAt: Date.now(),
      welcome: welcomeMeta,
    })

    if (initialCredits > 0) {
    transactions.push({ 
      id: nanoid(), 
      type: 'gift', 
      token, 
        amount: initialCredits,
      ref: 'new_user_welcome', 
        meta: { reason: '新用户注册赠送', deviceId: normalizeDeviceId(deviceId) },
        at: Date.now(),
    })
      console.log(`[Wallet] 新用户 ${token.substring(0, 8)}... 获得 ${initialCredits} 虫洞币 (device=${normalizeDeviceId(deviceId) || 'unknown'})`)
    } else {
      console.log(`[Wallet] 新用户 ${token.substring(0, 8)}... 创建钱包但未赠送虫洞币，原因=${welcomeMeta.reason}`)
    }
    
    scheduleSave()
  }
  return wallets.get(token)
}

function debitWallet(token, amount, ref, meta = {}) {
  const wallet = getWallet(token, { allowWelcome: false })
  wallet.balance = Math.max(0, wallet.balance - amount)
  transactions.push({ id: nanoid(), type: 'debit', token, amount, ref, meta, at: Date.now() })
  scheduleSave()
  return wallet.balance
}

function creditWallet(token, amount, ref, meta = {}) {
  const wallet = getWallet(token, { allowWelcome: false })
  wallet.balance += amount
  transactions.push({ id: nanoid(), type: 'topup', token, amount, ref, meta, at: Date.now() })
  scheduleSave()
  return wallet.balance
}

app.get('/health', (_, res) => res.json({ ok: true }))

app.get('/balance', (req, res) => {
  const appAccountToken = req.header('X-App-Account-Token') || req.query.appAccountToken
  const deviceId = req.header('X-Device-Id') || req.query.deviceId
  console.log('[BALANCE] Request from token:', appAccountToken ? `${appAccountToken.substring(0, 8)}...` : 'MISSING', '| device:', deviceId ? `${normalizeDeviceId(deviceId).slice(0, 8)}...` : 'MISSING')
  if (!appAccountToken) return res.status(400).json({ error: 'missing appAccountToken' })
  const wallet = getWallet(appAccountToken, { deviceId })
  console.log('[BALANCE] Current balance for token:', wallet.balance)
  if (wallet?.welcome) {
    res.setHeader('X-Welcome-Granted', wallet.welcome.granted ? '1' : '0')
    if (wallet.welcome.reason) res.setHeader('X-Welcome-Reason', wallet.welcome.reason)
  }
  res.json({ balance: wallet.balance, currency: 'CREDITS', welcome: wallet.welcome || null })
})

// 管理端点：设置余额（仅用于测试）
app.post('/admin/set-balance', (req, res) => {
  const { appAccountToken, balance } = req.body || {}
  if (!appAccountToken || typeof balance !== 'number') {
    return res.status(400).json({ error: 'missing appAccountToken or balance' })
  }
  const wallet = getWallet(appAccountToken, { allowWelcome: false })
  wallet.balance = Math.max(0, balance)
  transactions.push({ 
    id: nanoid(), 
    type: 'admin-set', 
    token: appAccountToken, 
    amount: balance, 
    ref: 'admin-adjustment', 
    meta: {}, 
    at: Date.now() 
  })
  scheduleSave()
  console.log(`[ADMIN] Set balance for ${appAccountToken.substring(0, 8)}... to ${balance}`)
  res.json({ balance: wallet.balance, currency: 'CREDITS' })
})

app.post('/purchase/confirm', async (req, res) => {
  const appAccountToken = req.body?.appAccountToken || req.header('X-App-Account-Token') || req.query.appAccountToken
  let { productId, transactionId, receipt } = req.body || {}
  
  // Debug log - 检查 receipt 格式
  const receiptType = typeof receipt
  const receiptPreview = receiptType === 'string' 
    ? (receipt.length > 100 ? receipt.substring(0, 100) + '...' : receipt)
    : (receiptType === 'object' ? JSON.stringify(receipt).substring(0, 100) + '...' : String(receipt))
  
  console.log('[IAP] confirm payload', { 
    appAccountToken, 
    productId, 
    transactionId, 
    hasReceipt: Boolean(receipt),
    receiptType,
    receiptPreview
  })
  
  // 检查 receipt 格式（在验证之前）
  // 如果 receipt 是对象，可能是 Express 自动解析了 JSON，或者是 Xcode 环境返回的对象格式
  // 这种情况下，我们需要使用对象验证方式
  
  if (!appAccountToken || !productId || !transactionId) return res.status(400).json({ error: 'missing params', got: { appAccountToken: !!appAccountToken, productId: !!productId, transactionId: !!transactionId } })

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
    'com.lishilong.chongyu.1400energy': 24000, // ¥68 = 1400能量
  }
  const credits = skuToCredits[productId]
  if (!credits) return res.status(400).json({ error: 'unknown productId', productId, supported: Object.keys(skuToCredits) })

  // Idempotency: prevent duplicate credits for the same transactionId
  if (processedIapTransactions.has(transactionId)) {
    const wallet = getWallet(appAccountToken, { allowWelcome: false })
    return res.json({ balance: wallet.balance, currency: 'CREDITS' })
  }

  // ✅ IAP验证：如果提供了 receipt，验证交易真实性
  // 支持三种格式：
  // 1. JWT 字符串格式（生产环境/Sandbox）- 以 "eyJ" 开头
  // 2. JSON 字符串格式（Xcode 环境）- 以 "{" 开头
  // 3. JSON 对象格式（Express 自动解析）
  let verificationResult = null
  let verificationWarning = null
  let receiptObject = null
  
  // 检查 receipt 格式并统一处理
  if (receipt) {
    // 如果 receipt 是字符串，检查是否是 JSON 字符串还是 JWT 字符串
    if (typeof receipt === 'string' && receipt.length > 0) {
      // 检查是否是 JSON 字符串（以 "{" 开头）
      if (receipt.trim().startsWith('{')) {
        // 情况2：receipt 是 JSON 字符串（Xcode 环境）
        try {
          receiptObject = JSON.parse(receipt)
          console.log('[IAP Verify] ℹ️ Receipt 是 JSON 字符串格式，已解析为对象')
        } catch (parseErr) {
          console.error('[IAP Verify] ❌ 无法解析 JSON 字符串:', parseErr.message)
          verificationWarning = {
            error: 'invalid_json_string',
            message: 'Receipt 是字符串但无法解析为 JSON'
          }
        }
      } else {
        // 情况1：receipt 是 JWT 字符串（生产环境/Sandbox）
        // 尝试 JWT 验证
        try {
          verificationResult = await verifyIAPTransaction(receipt, productId, transactionId)
        
        if (!verificationResult.valid) {
          const strictMode = process.env.IAP_VERIFY_STRICT === '1'
          verificationWarning = {
            error: verificationResult.error,
            reason: verificationResult.reason || 'unknown',
            strictMode
          }
          
          console.warn(`[IAP Verify] ⚠️ 交易验证失败: ${verificationResult.error}`, {
            productId,
            transactionId,
            reason: verificationResult.reason,
            strictMode
          })
          
          if (strictMode) {
            return res.status(400).json({ 
              error: 'iap_verification_failed', 
              reason: verificationResult.error,
              details: verificationWarning
            })
          }
          
          console.warn('[IAP Verify] ⚠️ 验证失败但继续处理（非严格模式）')
        } else {
          console.log('[IAP Verify] ✅ 交易验证成功', {
            productId,
            transactionId,
            purchaseDate: verificationResult.payload?.purchaseDate
          })
        }
      } catch (err) {
        const strictMode = process.env.IAP_VERIFY_STRICT === '1'
        verificationWarning = {
          error: 'verification_error',
          message: err.message,
          strictMode
        }
        
        console.error('[IAP Verify] ❌ 验证过程出错:', err.message)
        
        if (strictMode) {
          return res.status(500).json({ 
            error: 'iap_verification_error', 
            message: err.message 
          })
        }
        
        console.warn('[IAP Verify] ⚠️ 验证出错但继续处理（非严格模式）')
      }
      }
    }
    
    // 如果 receiptObject 已设置（从 JSON 字符串解析或直接是对象），进行对象验证
    if (receiptObject || (typeof receipt === 'object' && receipt !== null)) {
      if (!receiptObject) {
        receiptObject = receipt
      }
      
      // 验证对象中的关键信息
      const receiptProductId = receiptObject.productId || receiptObject.productID
      const receiptTransactionId = String(receiptObject.transactionId || receiptObject.originalTransactionId || '')
      const receiptBundleId = receiptObject.bundleId || receiptObject.bundleID
      
      // 基本验证：检查产品 ID 和交易 ID 是否匹配
      if (receiptProductId && receiptProductId !== productId) {
        verificationWarning = {
          error: 'product_id_mismatch',
          expected: productId,
          got: receiptProductId,
          receiptFormat: 'object'
        }
        console.warn(`[IAP Verify] ⚠️ 产品 ID 不匹配: expected ${productId}, got ${receiptProductId}`)
      } else if (receiptTransactionId && receiptTransactionId !== transactionId) {
        verificationWarning = {
          error: 'transaction_id_mismatch',
          expected: transactionId,
          got: receiptTransactionId,
          receiptFormat: 'object'
        }
        console.warn(`[IAP Verify] ⚠️ 交易 ID 不匹配: expected ${transactionId}, got ${receiptTransactionId}`)
      } else if (receiptBundleId && receiptBundleId !== APP_BUNDLE_ID) {
        verificationWarning = {
          error: 'bundle_id_mismatch',
          expected: APP_BUNDLE_ID,
          got: receiptBundleId,
          receiptFormat: 'object'
        }
        console.warn(`[IAP Verify] ⚠️ Bundle ID 不匹配: expected ${APP_BUNDLE_ID}, got ${receiptBundleId}`)
      } else if (receiptProductId && receiptTransactionId) {
        // 基本信息匹配，标记为已验证（对象格式）
        verificationResult = {
          valid: true,
          payload: receiptObject,
          format: 'object'
        }
        console.log('[IAP Verify] ✅ 交易验证成功（对象格式）', {
          productId: receiptProductId,
          transactionId: receiptTransactionId,
          environment: receiptObject.environment || 'unknown'
        })
      } else {
        // 对象格式但缺少关键信息
        verificationWarning = {
          error: 'incomplete_receipt_object',
          message: 'Receipt 对象缺少关键验证信息',
          receiptFormat: 'object',
          hasProductId: !!receiptProductId,
          hasTransactionId: !!receiptTransactionId
        }
        console.warn('[IAP Verify] ⚠️ Receipt 对象格式但缺少关键信息')
      }
      
      // 检查环境（Xcode 环境的 receipt 对象是正常的）
      if (receiptObject.environment === 'Xcode' || receiptObject.environment === 'Sandbox') {
        console.log(`[IAP Verify] ℹ️ Receipt 来自 ${receiptObject.environment} 环境，对象格式是正常的`)
      }
    } else {
      // receipt 格式未知
      verificationWarning = {
        error: 'unknown_receipt_format',
        receiptType: typeof receipt,
        message: 'Receipt 格式未知，无法验证'
      }
      console.warn(`[IAP Verify] ⚠️ Receipt 格式未知: ${typeof receipt}`)
    }
  } else {
    // 没有提供 receipt
    verificationWarning = {
      error: 'no_receipt_provided',
      message: 'iOS端未提供交易凭证，无法验证交易真实性'
    }
    console.warn('[IAP Verify] ⚠️ 未提供 receipt，无法验证交易真实性')
  }

  // 保存 receipt 用于审计（支持字符串和对象格式）
  let savedReceipt = receipt
  if (receiptObject) {
    // 如果 receipt 是对象，直接保存对象
    savedReceipt = receiptObject
  } else if (typeof receipt === 'string' && receipt.length) {
    // 如果 receipt 是字符串，尝试解析（可能是 JWT，解析会失败，那就保存字符串）
    try {
      savedReceipt = JSON.parse(receipt)
    } catch {
      // JWT 字符串无法解析为 JSON，这是正常的，保存原始字符串
      savedReceipt = receipt
    }
  }

  // 充值
  const balanceAfter = creditWallet(appAccountToken, credits, transactionId, { 
    productId, 
    receipt: savedReceipt,
    verification: verificationResult ? {
      valid: verificationResult.valid,
      error: verificationResult.error,
      format: verificationResult.format || 'jwt',
      warning: verificationWarning
    } : (verificationWarning ? {
      valid: false,
      error: verificationWarning.error,
      warning: verificationWarning
    } : null)
  })
  processedIapTransactions.add(transactionId)
  scheduleSave()
  
  // 返回结果（包含验证信息）
  const response = { 
    balance: balanceAfter, 
    currency: 'CREDITS' 
  }
  
  // 如果验证失败或有警告，在响应中包含警告信息（不影响成功状态）
  if (verificationWarning) {
    response.warning = verificationWarning
  }
  
  res.json(response)
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

// 通过token恢复账号（验证token是否存在）
app.post('/account/restore-by-token', (req, res) => {
  const { appAccountToken } = req.body || {}
  if (!appAccountToken) {
    return res.status(400).json({ error: 'missing appAccountToken' })
  }
  // 检查token是否存在（通过检查钱包是否存在）
  // 如果不存在，getWallet会创建新钱包，所以我们需要先检查
  if (!wallets.has(appAccountToken)) {
    return res.status(404).json({ error: 'token_not_found' })
  }
  // token存在，返回它
  res.json({ appAccountToken })
})

// 充值端点（用于处理应用内购买充值）
app.post('/recharge', (req, res) => {
  const appAccountToken = req.body?.appAccountToken || req.header('X-App-Account-Token')
  const { amount, currency = 'CREDITS' } = req.body || {}
  
  console.log('[Recharge] Request received', { appAccountToken: !!appAccountToken, amount, currency })
  
  if (!appAccountToken) {
    return res.status(400).json({ error: 'missing appAccountToken' })
  }
  
  if (typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({ error: 'invalid amount', amount })
  }
  
  // 执行充值
  const balanceAfter = creditWallet(appAccountToken, amount, `recharge_${Date.now()}`, { 
    type: 'recharge',
    currency 
  })
  
  scheduleSave()
  
  console.log('[Recharge] Success', { appAccountToken: appAccountToken.substring(0, 8), amount, balanceAfter })
  
  res.json({ 
    success: true,
    balance: balanceAfter, 
    currency,
    amount 
  })
})

app.post('/api/proxy', async (req, res) => {
  const appAccountToken = req.header('X-App-Account-Token') || req.body.appAccountToken
  if (!appAccountToken) return res.status(400).json({ error: 'missing appAccountToken' })

  const wallet = getWallet(appAccountToken, { allowWelcome: false })
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
    let inputTokens = 0
    let outputTokens = 0
    
    if (data?.usage?.total_tokens != null) {
      totalTokens = Number(data.usage.total_tokens)
      inputTokens = Number(data.usage.input_tokens || 0)
      outputTokens = Number(data.usage.output_tokens || 0)
    } else if (data?.usage?.input_tokens != null || data?.usage?.output_tokens != null) {
      inputTokens = Number(data.usage.input_tokens || 0)
      outputTokens = Number(data.usage.output_tokens || 0)
      totalTokens = inputTokens + outputTokens
    } else {
      // fallback rough estimate
      totalTokens = 800
      inputTokens = 200
      outputTokens = 600
    }

    const costCredits = Math.floor((totalTokens / 1000) * CREDITS_TEXT_PER_1K_TOKENS)
    
    // 详细计费日志：记录输入/输出 tokens 用于价格验证
    const inputCost = (inputTokens / 1000) * 0.004  // 假设输入价格 ¥0.004/1K
    const outputCost = (outputTokens / 1000) * 0.016  // 假设输出价格 ¥0.016/1K
    const estimatedApiCost = inputCost + outputCost
    console.log(`[Billing] 文本API计费详情:`)
    console.log(`  - 总tokens: ${totalTokens} (输入: ${inputTokens}, 输出: ${outputTokens})`)
    console.log(`  - 输入:输出比例: ${inputTokens > 0 ? (outputTokens / inputTokens).toFixed(2) : 'N/A'}:1`)
    console.log(`  - 估算API成本: ¥${estimatedApiCost.toFixed(4)} (输入¥${inputCost.toFixed(4)} + 输出¥${outputCost.toFixed(4)})`)
    console.log(`  - 虫洞币费率: ${CREDITS_TEXT_PER_1K_TOKENS}/1K, 扣费: ${costCredits}虫洞币`)

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

// 通义千问 3-VL-Flash 视觉API代理端点
app.post('/api/vision', async (req, res) => {
  const appAccountToken = req.header('X-App-Account-Token') || req.body.appAccountToken
  if (!appAccountToken) return res.status(400).json({ error: 'missing appAccountToken' })

  const wallet = getWallet(appAccountToken, { allowWelcome: false })
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
  
  // 通义千问 3-VL-Flash 视觉API配置（OpenAI兼容接口）
  const QWEN_VISION_ENDPOINT = process.env.QWEN_VISION_ENDPOINT || 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions'
  const QWEN_VISION_API_KEY = process.env.QWEN_VISION_API_KEY || ''
  const QWEN_VISION_MODEL = model || process.env.QWEN_VISION_MODEL || 'qwen3-vl-flash'

  // 调试日志：确认配置是否正确加载
  console.log('[Vision API] 🔧 配置检查:')
  console.log(`  - Endpoint: ${QWEN_VISION_ENDPOINT}`)
  console.log(`  - Model: ${QWEN_VISION_MODEL}`)
  console.log(`  - API Key: ${QWEN_VISION_API_KEY ? QWEN_VISION_API_KEY.substring(0, 10) + '...' : '❌ 未配置'}`)

  if (!QWEN_VISION_API_KEY) {
    console.error('[Vision API] ❌ 错误: QWEN_VISION_API_KEY 未配置！')
    return res.status(500).json({ error: 'Vision API key not configured' })
  }

  const payload = {
    model: QWEN_VISION_MODEL,
    messages,
    max_tokens: max_tokens || 1000,
    temperature: temperature || 0.3,
    ...rest,
  }

  const startTime = Date.now() // 移到 try 块之前，确保 catch 块可以访问

  try {
    console.log('[Vision API] 🚀 调用通义千问 3-VL-Flash 视觉API')
    
    const visionResp = await axios.post(QWEN_VISION_ENDPOINT, payload, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${QWEN_VISION_API_KEY}`,
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

    // 视觉API使用单独的计费标准
    const costCredits = Math.floor((totalTokens / 1000) * CREDITS_VISION_PER_1K_TOKENS)
    
    // 调试日志：显示实际使用的费率
    console.log(`[Billing] 视觉API计费: ${totalTokens} tokens, 费率=${CREDITS_VISION_PER_1K_TOKENS}/1K, 计算=${(totalTokens / 1000) * CREDITS_VISION_PER_1K_TOKENS}, 扣费=${costCredits}虫洞币`)

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
      console.error(`[Vision API] 通义视觉API响应状态: ${err.response.status}`)
      console.error(`[Vision API] 通义视觉API错误详情:`, JSON.stringify(err.response.data, null, 2))
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
  console.log(`[Config] CREDITS_PER_1K_TOKENS = ${CREDITS_PER_1K_TOKENS}`)
  console.log(`[Config] CREDITS_TEXT_PER_1K_TOKENS = ${CREDITS_TEXT_PER_1K_TOKENS}`)
  console.log(`[Config] CREDITS_VISION_PER_1K_TOKENS = ${CREDITS_VISION_PER_1K_TOKENS}`)
  console.log(`[Config] INITIAL_WELCOME_CREDITS = ${INITIAL_WELCOME_CREDITS}`)
  console.log(`[Config] PROVIDER_MODEL = ${PROVIDER_MODEL}`)
  console.log(`[Config] NODE_ENV = ${process.env.NODE_ENV || 'development'}`)
}) 
// Extend HTTP server timeouts to allow long-running AI requests
server.headersTimeout = 305_000
server.requestTimeout = 305_000
server.keepAliveTimeout = 120_000 