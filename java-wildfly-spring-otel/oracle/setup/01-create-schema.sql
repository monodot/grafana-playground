-- Run once by the oracle-init container, as SYSDBA against the CDB.
-- (The "lite" Oracle image does not run /opt/oracle/scripts/setup scripts itself.)
ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE USER orders IDENTIFIED BY ordersdemo1;
GRANT CONNECT, RESOURCE TO orders;
GRANT UNLIMITED TABLESPACE TO orders;

CREATE TABLE orders.orders (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR2(20)  NOT NULL,
    item        VARCHAR2(50)  NOT NULL,
    quantity    NUMBER        DEFAULT 1,
    source      VARCHAR2(30),
    created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP
);

-- Work queue for the batch job. It SELECTs PENDING rows, submits each order to
-- the gateway API, then marks the row EXPORTED. When nothing is left it resets
-- all rows to PENDING so the demo keeps producing batch traces.
CREATE TABLE orders.pending_exports (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR2(20)  NOT NULL,
    item        VARCHAR2(50)  NOT NULL,
    quantity    NUMBER        DEFAULT 1,
    status      VARCHAR2(10)  DEFAULT 'PENDING'
);

INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0101', 'anvil', 2);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0102', 'rocket-skates', 1);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0103', 'giant-magnet', 1);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0104', 'bird-seed', 40);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0105', 'tunnel-paint', 3);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0106', 'dehydrated-boulders', 12);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0107', 'jet-propelled-unicycle', 1);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0108', 'portable-hole', 2);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0109', 'earthquake-pills', 6);
INSERT INTO orders.pending_exports (customer_id, item, quantity) VALUES ('CUST-0110', 'triple-strength-fortified-leg-muscle-vitamins', 1);
COMMIT;

EXIT;
