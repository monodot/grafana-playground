const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = 3000;

// Middleware to parse JSON bodies
app.use(express.json());

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'snaxdb',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'supernature',
});

// Initialize database table
async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS snacks (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('SNACKS table initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// GET all snacks
app.get('/snacks', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM snacks ORDER BY id');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching snacks:', error);
    res.status(500).json({ error: 'Failed to fetch snacks' });
  }
});

// GET a single snack by ID
app.get('/snacks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM snacks WHERE id = $1', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Snack not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching snack:', error);
    res.status(500).json({ error: 'Failed to fetch snack' });
  }
});

// POST create a new snack
app.post('/snacks', async (req, res) => {
  try {
    const { name, description, price } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Name is required' });
    }

    const result = await pool.query(
      'INSERT INTO snacks (name, description, price) VALUES ($1, $2, $3) RETURNING *',
      [name, description, price]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating snack:', error);
    res.status(500).json({ error: 'Failed to create snack' });
  }
});

// PUT update a snack
app.put('/snacks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price } = req.body;

    const result = await pool.query(
      'UPDATE snacks SET name = COALESCE($1, name), description = COALESCE($2, description), price = COALESCE($3, price) WHERE id = $4 RETURNING *',
      [name, description, price, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Snack not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating snack:', error);
    res.status(500).json({ error: 'Failed to update snack' });
  }
});

// DELETE a snack
app.delete('/snacks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM snacks WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Snack not found' });
    }

    res.json({ message: 'Snack deleted successfully', snack: result.rows[0] });
  } catch (error) {
    console.error('Error deleting snack:', error);
    res.status(500).json({ error: 'Failed to delete snack' });
  }
});

// Start server
async function start() {
  await initDatabase();
  app.listen(port, '0.0.0.0', () => {
    console.log(`Snacks API listening on port ${port}`);
  });
}

start();
