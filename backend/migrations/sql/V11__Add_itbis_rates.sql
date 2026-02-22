-- V11__Add_itbis_rates.sql
-- Table of ITBIS (tax) percentages. Each product must have one rate.

-- 1. Create itbis_rates table (global, not per-organization)
CREATE TABLE IF NOT EXISTS itbis_rates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    percentage DECIMAL(5,2) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS update_itbis_rates_updated_at ON itbis_rates;
CREATE TRIGGER update_itbis_rates_updated_at
    BEFORE UPDATE ON itbis_rates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Seed 18% and 0% (skip if already exist)
INSERT INTO itbis_rates (name, percentage)
SELECT 'ITBIS 18%', 18.00 WHERE NOT EXISTS (SELECT 1 FROM itbis_rates WHERE percentage = 18);
INSERT INTO itbis_rates (name, percentage)
SELECT 'Exento (0%)', 0.00 WHERE NOT EXISTS (SELECT 1 FROM itbis_rates WHERE percentage = 0);

-- 3. Add itbis_rate_id to items (mandatory per product)
ALTER TABLE items ADD COLUMN IF NOT EXISTS itbis_rate_id INTEGER;

-- Backfill existing items with 18% (first rate)
UPDATE items SET itbis_rate_id = (SELECT id FROM itbis_rates WHERE percentage = 18 LIMIT 1) WHERE itbis_rate_id IS NULL;

ALTER TABLE items ALTER COLUMN itbis_rate_id SET NOT NULL;
ALTER TABLE items DROP CONSTRAINT IF EXISTS items_itbis_rate_id_fkey;
ALTER TABLE items ADD CONSTRAINT items_itbis_rate_id_fkey
    FOREIGN KEY (itbis_rate_id) REFERENCES itbis_rates(id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS idx_items_itbis_rate_id ON items(itbis_rate_id);
