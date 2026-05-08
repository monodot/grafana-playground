import { Hono } from 'hono'
import { serve } from '@hono/node-server'

const app = new Hono()
const customers = new Map()
let nextId = 1

app.get('/customers', (c) => c.json([...customers.values()]))

app.get('/customers/:id', (c) => c.json(customers.get(Number(c.req.param('id')))))

app.post('/customers', async (c) => {
  const body = await c.req.json()
  const id = nextId++
  const customer = { id, ...body }
  customers.set(id, customer)
  return c.json(customer, 201)
})

app.delete('/customers/:id', (c) => {
  customers.delete(Number(c.req.param('id')))
  return c.body(null, 204)
})

serve({ fetch: app.fetch, port: 8080, hostname: '0.0.0.0' })
console.log('server listening on :8080')
