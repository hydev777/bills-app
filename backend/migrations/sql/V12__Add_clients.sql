-- V12__Add_clients.sql
-- Global clients table (no organization). Any organization can assign any client to a bill.

-- 1. Create clients table (global, no organization_id)
CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    identifier VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS update_clients_updated_at ON clients;
CREATE TRIGGER update_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_clients_name ON clients(name);
CREATE INDEX IF NOT EXISTS idx_clients_identifier ON clients(identifier);

-- 2. Add client_id to bills (optional; null = "al contado")
ALTER TABLE bills ADD COLUMN IF NOT EXISTS client_id INTEGER;

ALTER TABLE bills DROP CONSTRAINT IF EXISTS bills_client_id_fkey;
ALTER TABLE bills ADD CONSTRAINT bills_client_id_fkey
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_bills_client_id ON bills(client_id);
