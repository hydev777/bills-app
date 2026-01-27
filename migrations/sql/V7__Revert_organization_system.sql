-- V7__Revert_organization_system.sql
-- Reverts multi-tenant organization system and company_settings (SaaS)
-- WARNING: Destructive. Backup data before running. Drops organizations, company_settings,
-- and organization_id from users, bills, items, item_categories, branches.

-- 1. Drop company_settings (depends on organizations)
DROP TABLE IF EXISTS company_settings CASCADE;

-- 2. Users: drop org-specific indexes and FK, then drop organization_id
DROP INDEX IF EXISTS idx_users_org_email;
DROP INDEX IF EXISTS idx_users_org_username;
DROP INDEX IF EXISTS idx_users_organization_id;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_organization_id_fkey;
ALTER TABLE users DROP COLUMN IF EXISTS organization_id;
-- Restore global uniques (V1 had these)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- 3. Bills: drop org index, FK, invoice_number; drop organization_id
DROP INDEX IF EXISTS idx_bills_org_invoice;
DROP INDEX IF EXISTS idx_bills_organization_id;
ALTER TABLE bills DROP CONSTRAINT IF EXISTS bills_organization_id_fkey;
ALTER TABLE bills DROP COLUMN IF EXISTS organization_id;
ALTER TABLE bills DROP COLUMN IF EXISTS invoice_number;

-- 4. Item categories: drop org index and FK, drop organization_id
DROP INDEX IF EXISTS idx_item_categories_org_name;
DROP INDEX IF EXISTS idx_item_categories_organization_id;
ALTER TABLE item_categories DROP CONSTRAINT IF EXISTS item_categories_organization_id_fkey;
ALTER TABLE item_categories DROP COLUMN IF EXISTS organization_id;
CREATE UNIQUE INDEX IF NOT EXISTS idx_item_categories_name ON item_categories(name);

-- 5. Items: drop index and FK, drop organization_id
DROP INDEX IF EXISTS idx_items_organization_id;
ALTER TABLE items DROP CONSTRAINT IF EXISTS items_organization_id_fkey;
ALTER TABLE items DROP COLUMN IF EXISTS organization_id;

-- 6. Branches: drop org index and FK, drop organization_id
DROP INDEX IF EXISTS idx_branches_org_code;
DROP INDEX IF EXISTS idx_branches_organization_id;
ALTER TABLE branches DROP CONSTRAINT IF EXISTS branches_organization_id_fkey;
ALTER TABLE branches DROP COLUMN IF EXISTS organization_id;
CREATE UNIQUE INDEX IF NOT EXISTS idx_branches_code ON branches(code);

-- 7. Drop organizations table and its trigger
DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
DROP TABLE IF EXISTS organizations CASCADE;
