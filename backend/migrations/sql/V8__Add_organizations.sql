-- V8__Add_organizations.sql
-- Users and data scoped by organization (un negocio con varios usuarios)

-- 1. Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Add organization_id to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS organization_id INTEGER;
-- Insert default org for existing data (if any)
INSERT INTO organizations (name)
SELECT 'Default' WHERE NOT EXISTS (SELECT 1 FROM organizations LIMIT 1);
UPDATE users SET organization_id = (SELECT id FROM organizations LIMIT 1) WHERE organization_id IS NULL;
ALTER TABLE users ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_organization_id_fkey;
ALTER TABLE users ADD CONSTRAINT users_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

-- Drop global uniques, add per-org uniques
DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_users_username;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_org_email ON users(organization_id, email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_org_username ON users(organization_id, username);
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);

-- 3. Add organization_id to bills
ALTER TABLE bills ADD COLUMN IF NOT EXISTS organization_id INTEGER;
UPDATE bills b SET organization_id = (SELECT organization_id FROM users u WHERE u.id = b.user_id LIMIT 1) WHERE organization_id IS NULL;
ALTER TABLE bills ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE bills DROP CONSTRAINT IF EXISTS bills_organization_id_fkey;
ALTER TABLE bills ADD CONSTRAINT bills_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_bills_organization_id ON bills(organization_id);

-- 4. Add organization_id to item_categories
ALTER TABLE item_categories ADD COLUMN IF NOT EXISTS organization_id INTEGER;
UPDATE item_categories SET organization_id = (SELECT id FROM organizations LIMIT 1) WHERE organization_id IS NULL;
ALTER TABLE item_categories ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE item_categories DROP CONSTRAINT IF EXISTS item_categories_organization_id_fkey;
ALTER TABLE item_categories ADD CONSTRAINT item_categories_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;
DROP INDEX IF EXISTS idx_item_categories_name;
-- Non-unique index to avoid failure when duplicate (organization_id, name) exist; enforce uniqueness in app if needed
DROP INDEX IF EXISTS idx_item_categories_org_name;
CREATE INDEX IF NOT EXISTS idx_item_categories_org_name ON item_categories(organization_id, name);
CREATE INDEX IF NOT EXISTS idx_item_categories_organization_id ON item_categories(organization_id);

-- 5. Add organization_id to items
ALTER TABLE items ADD COLUMN IF NOT EXISTS organization_id INTEGER;
UPDATE items SET organization_id = (SELECT id FROM organizations LIMIT 1) WHERE organization_id IS NULL;
ALTER TABLE items ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE items DROP CONSTRAINT IF EXISTS items_organization_id_fkey;
ALTER TABLE items ADD CONSTRAINT items_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_items_organization_id ON items(organization_id);

-- 6. Add organization_id to branches
ALTER TABLE branches ADD COLUMN IF NOT EXISTS organization_id INTEGER;
UPDATE branches SET organization_id = (SELECT id FROM organizations LIMIT 1) WHERE organization_id IS NULL;
ALTER TABLE branches ALTER COLUMN organization_id SET NOT NULL;
ALTER TABLE branches DROP CONSTRAINT IF EXISTS branches_organization_id_fkey;
ALTER TABLE branches ADD CONSTRAINT branches_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;
DROP INDEX IF EXISTS idx_branches_code;
-- Non-unique index to avoid failure when duplicate (organization_id, code) exist
DROP INDEX IF EXISTS idx_branches_org_code;
CREATE INDEX IF NOT EXISTS idx_branches_org_code ON branches(organization_id, code);
CREATE INDEX IF NOT EXISTS idx_branches_organization_id ON branches(organization_id);
