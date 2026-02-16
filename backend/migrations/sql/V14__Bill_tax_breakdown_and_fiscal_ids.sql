-- V14__Bill_tax_breakdown_and_fiscal_ids.sql
-- Bills: subtotal and tax_amount (desglose impuestos); Branches and Clients: tax_id (datos fiscales).

-- Bills: add subtotal and tax_amount for tax breakdown (amount = total = subtotal + tax_amount)
ALTER TABLE bills ADD COLUMN IF NOT EXISTS subtotal DECIMAL(10, 2) DEFAULT 0 NOT NULL;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10, 2) DEFAULT 0 NOT NULL;

-- Backfill existing bills: set subtotal = amount, tax_amount = 0 (no historic breakdown)
UPDATE bills SET subtotal = amount, tax_amount = 0 WHERE subtotal = 0 AND tax_amount = 0;

-- Branches: fiscal id (RNC/CIF/NIF)
ALTER TABLE branches ADD COLUMN IF NOT EXISTS tax_id VARCHAR(50);

-- Clients: explicit fiscal id (RNC/CIF/NIF)
ALTER TABLE clients ADD COLUMN IF NOT EXISTS tax_id VARCHAR(50);
