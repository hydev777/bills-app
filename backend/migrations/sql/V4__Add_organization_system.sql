-- V4__Add_organization_system.sql
-- Migration to add multi-tenant organization system

-- Create organizations table (tenants)
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    plan VARCHAR(50) DEFAULT 'free', -- free, basic, premium
    subscription_status VARCHAR(50) DEFAULT 'active', -- active, suspended, cancelled
    subscription_ends_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure columns exist (idempotent: table may already exist from a previous run without these columns)
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS plan VARCHAR(50) DEFAULT 'free';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'active';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS subscription_ends_at TIMESTAMP NULL;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Create index for organizations
CREATE INDEX IF NOT EXISTS idx_organizations_plan ON organizations(plan);
CREATE INDEX IF NOT EXISTS idx_organizations_subscription_status ON organizations(subscription_status);

-- Add organization_id to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'user'; -- owner, admin, user

-- Create unique constraints for users within organization
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_org_email ON users(organization_id, email) WHERE organization_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_org_username ON users(organization_id, username) WHERE organization_id IS NOT NULL;

-- Create index for organization_id in users
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);

-- Add organization_id to bills table
ALTER TABLE bills 
ADD COLUMN IF NOT EXISTS organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS invoice_number VARCHAR(50) NULL;

-- Create unique constraint for invoice_number within organization
CREATE UNIQUE INDEX IF NOT EXISTS idx_bills_org_invoice ON bills(organization_id, invoice_number) 
WHERE organization_id IS NOT NULL AND invoice_number IS NOT NULL;

-- Create indexes for bills
CREATE INDEX IF NOT EXISTS idx_bills_organization_id ON bills(organization_id);

-- Add organization_id to item_categories table
ALTER TABLE item_categories 
ADD COLUMN IF NOT EXISTS organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE;

-- Index for category name within organization (non-unique to allow existing duplicate names; enforce uniqueness in app or later migration)
DROP INDEX IF EXISTS idx_item_categories_org_name;
CREATE INDEX IF NOT EXISTS idx_item_categories_org_name ON item_categories(organization_id, name)
WHERE organization_id IS NOT NULL;

-- Create index for organization_id in item_categories
CREATE INDEX IF NOT EXISTS idx_item_categories_organization_id ON item_categories(organization_id);

-- Add organization_id to items table
ALTER TABLE items 
ADD COLUMN IF NOT EXISTS organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE;

-- Create index for organization_id in items
CREATE INDEX IF NOT EXISTS idx_items_organization_id ON items(organization_id);

-- Add organization_id to branches table
ALTER TABLE branches 
ADD COLUMN IF NOT EXISTS organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE;

-- Create unique constraint for branch code within organization
CREATE UNIQUE INDEX IF NOT EXISTS idx_branches_org_code ON branches(organization_id, code) 
WHERE organization_id IS NOT NULL;

-- Create index for organization_id in branches
CREATE INDEX IF NOT EXISTS idx_branches_organization_id ON branches(organization_id);

-- Create trigger to update updated_at timestamp for organizations (DROP IF EXISTS so re-run is safe)
DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at 
    BEFORE UPDATE ON organizations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
