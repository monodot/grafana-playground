-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Create index for polling query
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Insert sample pending orders
INSERT INTO orders (order_number, customer_name, amount, status) VALUES
    ('ORD-001', 'Alice Johnson', 149.99, 'PENDING'),
    ('ORD-002', 'Bob Smith', 299.50, 'PENDING'),
    ('ORD-003', 'Carol White', 89.99, 'PENDING'),
    ('ORD-004', 'David Brown', 499.00, 'PENDING'),
    ('ORD-005', 'Eve Davis', 175.25, 'PENDING'),
    ('ORD-006', 'Frank Miller', 329.99, 'PENDING'),
    ('ORD-007', 'Grace Wilson', 199.00, 'PENDING'),
    ('ORD-008', 'Henry Moore', 445.50, 'PENDING'),
    ('ORD-009', 'Ivy Taylor', 99.99, 'PENDING'),
    ('ORD-010', 'Jack Anderson', 275.75, 'PENDING')
ON CONFLICT (order_number) DO NOTHING;
