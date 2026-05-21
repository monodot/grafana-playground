import { Hono } from 'hono'
import { serve } from '@hono/node-server'

const SERVER = process.env.SERVER_URL || 'http://server:8080'

const app = new Hono()
const placed = []

const traders = [
  { traderId: 'HF-001',  accountType: 'highfreq', firm: 'Apex Quant' },
  { traderId: 'HF-002',  accountType: 'highfreq', firm: 'Vertex Markets' },
  { traderId: 'PRO-014', accountType: 'pro',      firm: 'Meridian Brokers' },
  { traderId: 'PRO-027', accountType: 'pro',      firm: 'Helios Capital' },
  { traderId: 'RET-042', accountType: 'retail',   firm: null },
  { traderId: 'RET-088', accountType: 'retail',   firm: null },
]

const symbols    = ['AAPL', 'NVDA', 'MSFT', 'SBRY', 'TSCO']
const sides      = ['buy', 'sell']
const orderTypes = ['market', 'limit']

const randomTrade = () => {
  const trader = traders[Math.floor(Math.random() * traders.length)]
  return {
    traderId:    trader.traderId,
    accountType: trader.accountType,
    firm:        trader.firm,
    symbol:      symbols[Math.floor(Math.random() * symbols.length)],
    side:        sides[Math.floor(Math.random() * sides.length)],
    orderType:   orderTypes[Math.floor(Math.random() * orderTypes.length)],
    quantity:    Math.floor(Math.random() * 500) + 1,
    price:       Math.round((Math.random() * 400 + 50) * 100) / 100,
  }
}

app.post('/trades', async (c) => {
  const trade = randomTrade()
  const created = await fetch(`${SERVER}/orders`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(trade),
  }).then((r) => r.json())
  placed.push(created)
  return c.json(created, 201)
})

app.get('/trades', (c) => c.json(placed))

setInterval(async () => {
  const trade = randomTrade()
  const created = await fetch(`${SERVER}/orders`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(trade),
  }).then((r) => r.json())
  await fetch(`${SERVER}/orders`).then((r) => r.json())
  console.log('placed order', created.id, 'for', trade.traderId, '(' + trade.accountType + ')')
}, 500)

serve({ fetch: app.fetch, port: 3001, hostname: '0.0.0.0' })
console.log('client listening on :3001')