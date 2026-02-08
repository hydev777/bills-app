-- V9__Add_bill_public_id.sql
-- Add a unique public ID (UUID) to each bill for external reference

ALTER TABLE bills ADD COLUMN IF NOT EXISTS public_id UUID;

-- Backfill existing rows with a unique UUID each
UPDATE bills SET public_id = gen_random_uuid() WHERE public_id IS NULL;

ALTER TABLE bills ALTER COLUMN public_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_bills_public_id ON bills(public_id);

-- Default for future inserts (e.g. from raw SQL)
ALTER TABLE bills ALTER COLUMN public_id SET DEFAULT gen_random_uuid();
