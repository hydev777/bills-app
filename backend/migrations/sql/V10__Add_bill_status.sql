-- V10__Add_bill_status.sql
-- Add status to bills: draft, issued, paid, cancelled

ALTER TABLE bills ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'draft';

CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
