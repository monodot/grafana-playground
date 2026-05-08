import { Hono } from 'hono'
import { serve } from '@hono/node-server'

const SERVER = process.env.SERVER_URL || 'http://server:8080'

const app = new Hono()
const orders = []

const sample = [
  { firstName: 'Ada', lastName: 'Lovelace', address: '1 Analytical St', state: 'London', country: 'UK' },
  { firstName: 'Alan', lastName: 'Turing', address: '2 Bombe Rd', state: 'Manchester', country: 'UK' },
  { firstName: 'Grace', lastName: 'Hopper', address: '3 Cobol Ave', state: 'NY', country: 'USA' },
  { firstName: 'Linus', lastName: 'Torvalds', address: '4 Kernel Way', state: 'OR', country: 'USA' },
]

app.post('/orders', async (c) => {
  const customer = sample[Math.floor(Math.random() * sample.length)]
  const created = await fetch(`${SERVER}/customers`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(customer),
  }).then((r) => r.json())
  const order = { id: orders.length + 1, customerId: created.id, item: 'widget', qty: 1 }
  orders.push(order)
  return c.json(order, 201)
})

app.get('/orders', (c) => c.json(orders))

setInterval(async () => {
  const customer = sample[Math.floor(Math.random() * sample.length)]
  const created = await fetch(`${SERVER}/customers`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(customer),
  }).then((r) => r.json())
  await fetch(`${SERVER}/customers`).then((r) => r.json())
  console.log('placed order for customer', created.id)
}, 5000)

serve({ fetch: app.fetch, port: 3001, hostname: '0.0.0.0' })
console.log('client listening on :3001')
