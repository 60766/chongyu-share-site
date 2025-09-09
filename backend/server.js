import express from 'express'
import cors from 'cors'
import morgan from 'morgan'
import axios from 'axios'
import { nanoid } from 'nanoid'
import dotenv from 'dotenv'

dotenv.config()

const app = express()
app.use(cors())
app.use(express.json({ limit: '2mb' }))
app.use(morgan('dev'))

// In-memory store for demo. Replace with persistent DB in production.
const wallets = new Map() // key: appAccountToken, value: { balance: number }
const transactions = []
const processedIapTransactions = new Set()

const CREDITS_PER_1K_TOKENS = Number(process.env.CREDITS_PER_1K_TOKENS || 100) // example: 100 credits / 1k tokens
const PROVIDER_ENDPOINT = process.env.PROVIDER_ENDPOINT || 'https://ark.cn-beijing.volces.com/api/v3/chat/completions'
const PROVIDER_MODEL = process.env.PROVIDER_MODEL || 'deepseek-r1-250120'
const PROVIDER_API_KEY = process.env.PROVIDER_API_KEY || 'demo_key_placeholder'

// Debug configuration (does not print the actual key)
console.log('[Config] PROVIDER_ENDPOINT:', PROVIDER_ENDPOINT)
console.log('[Config] PROVIDER_MODEL:', PROVIDER_MODEL)
console.log('[Config] MOCK_PROVIDER:', process.env.MOCK_PROVIDER || 'not set')
console.log('[Config] API key provided:', PROVIDER_API_KEY && PROVIDER_API_KEY !== 'demo_key_placeholder' ? 'yes' : 'no')

function getWallet(token) {
  if (!wallets.has(token)) wallets.set(token, { balance: 0 })
  return wallets.get(token)
}

function debitWallet(token, amount, ref, meta = {}) {
  const wallet = getWallet(token)
  wallet.balance = Math.max(0, wallet.balance - amount)
  transactions.push({ id: nanoid(), type: 'debit', token, amount, ref, meta, at: Date.now() })
  return wallet.balance
}

function creditWallet(token, amount, ref, meta = {}) {
  const wallet = getWallet(token)
  wallet.balance += amount
  transactions.push({ id: nanoid(), type: 'topup', token, amount, ref, meta, at: Date.now() })
  return wallet.balance
}

app.get('/health', (_, res) => res.json({ ok: true }))

app.get('/balance', (req, res) => {
  const appAccountToken = req.header('X-App-Account-Token') || req.query.appAccountToken
  if (!appAccountToken) return res.status(400).json({ error: 'missing appAccountToken' })
  const wallet = getWallet(appAccountToken)
  res.json({ balance: wallet.balance, currency: 'CREDITS' })
})

app.post('/purchase/confirm', (req, res) => {
  const appAccountToken = req.body?.appAccountToken || req.header('X-App-Account-Token') || req.query.appAccountToken
  const { productId, transactionId, receipt } = req.body || {}
  // Debug log
  console.log('[IAP] confirm payload', { appAccountToken, productId, transactionId, hasReceipt: Boolean(receipt) })
  if (!appAccountToken || !productId || !transactionId) return res.status(400).json({ error: 'missing params', got: { appAccountToken: !!appAccountToken, productId: !!productId, transactionId: !!transactionId } })

  // TODO: verify with App Store Server API using receipt. For MVP, accept and credit by SKU table.
  const skuToCredits = {
    'credits.small': 1800,      // ¥6 入门包
    'credits.medium': 6000,     // ¥18 标准包
    'credits.large': 13800,     // ¥38 豪华包
    'credits.xlarge': 26800,    // ¥68 至尊包
  }
  const credits = skuToCredits[productId]
  if (!credits) return res.status(400).json({ error: 'unknown productId', productId })

  // Idempotency: prevent duplicate credits for the same transactionId
  if (processedIapTransactions.has(transactionId)) {
    const wallet = getWallet(appAccountToken)
    return res.json({ balance: wallet.balance, currency: 'CREDITS' })
  }

  const balanceAfter = creditWallet(appAccountToken, credits, transactionId, { productId, receipt })
  processedIapTransactions.add(transactionId)
  res.json({ balance: balanceAfter, currency: 'CREDITS' })
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
        id: nanoid(),
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
        timeout: 60_000,
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

    const balanceAfter = debitWallet(appAccountToken, costCredits, nanoid(), { totalTokens, providerModel: payload.model })

    res.setHeader('X-Usage-Tokens', String(totalTokens))
    res.setHeader('X-Cost-Credits', String(costCredits))
    res.setHeader('X-Balance-After', String(balanceAfter))
    res.json(data)
  } catch (err) {
    const status = err.response?.status || 500
    const body = err.response?.data || { error: 'provider_error', message: err.message }
    res.status(status).json(body)
  }
})

const port = process.env.PORT || 8787
app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`)
}) 