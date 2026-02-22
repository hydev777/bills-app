-- V6__Add_company_settings.sql
-- Migration to add company settings for invoice printing

-- Create company_settings table
CREATE TABLE IF NOT EXISTS company_settings (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL UNIQUE REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    nit VARCHAR(50), -- Tax ID / NIT
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    logo VARCHAR(255), -- URL or file path
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for company_settings
CREATE INDEX IF NOT EXISTS idx_company_settings_organization_id ON company_settings(organization_id);

-- Create trigger to update updated_at timestamp for company_settings (DROP IF EXISTS so re-run is safe)
DROP TRIGGER IF EXISTS update_company_settings_updated_at ON company_settings;
CREATE TRIGGER update_company_settings_updated_at 
    BEFORE UPDATE ON company_settings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
