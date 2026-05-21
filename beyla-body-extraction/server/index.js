import { Hono } from 'hono'
import { serve } from '@hono/node-server'

const app = new Hono()
const orders = new Map()
let nextId = 1

// Per-tier latency bands. Retail goes through the public gateway and queues;
// pro has direct API access; highfreq is on the co-located fast path.
const latencyByAccountType = {
  highfreq: [5, 15],
  pro:      [60, 100],
  retail:   [250, 450],
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

const simulateExecution = async (accountType) => {
  const [min, max] = latencyByAccountType[accountType] ?? [50, 100]
  await sleep(Math.floor(Math.random() * (max - min + 1)) + min)
}

app.get('/orders', (c) => c.json([...orders.values()]))

app.get('/orders/:id', (c) => c.json(orders.get(Number(c.req.param('id')))))

app.post('/orders', async (c) => {
  const body = await c.req.json()
  await simulateExecution(body.accountType)
  const id = nextId++
  const order = { id, status: 'filled', ...body }
  orders.set(id, order)
  return c.json(order, 201)
})

app.delete('/orders/:id', (c) => {
  orders.delete(Number(c.req.param('id')))
  return c.body(null, 204)
})

serve({ fetch: app.fetch, port: 8080, hostname: '0.0.0.0' })
console.log('server listening on :8080')