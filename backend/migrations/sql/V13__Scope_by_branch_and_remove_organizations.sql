-- V13__Scope_by_branch_and_remove_organizations.sql
-- Scope bills, items, item_categories by branch; remove organization_id from users and branches; drop organizations.

-- ========== PHASE A: Bills, items, item_categories by branch ==========

-- 1. Ensure every organization has at least one branch (for backfill)
INSERT INTO branches (organization_id, name, code, address, phone, email, is_active, created_at, updated_at)
SELECT o.id, 'Sucursal principal', 'PRINCIPAL-' || o.id, NULL, NULL, NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM branches b WHERE b.organization_id = o.id);

-- 2. Bills: add branch_id, backfill, NOT NULL, FK RESTRICT, drop organization_id
ALTER TABLE bills ADD COLUMN IF NOT EXISTS branch_id INTEGER;

UPDATE bills b
SET branch_id = (SELECT id FROM branches br WHERE br.organization_id = b.organization_id ORDER BY id LIMIT 1)
WHERE b.branch_id IS NULL;

ALTER TABLE bills ALTER COLUMN branch_id SET NOT NULL;

ALTER TABLE bills DROP CONSTRAINT IF EXISTS bills_organization_id_fkey;
DROP INDEX IF EXISTS idx_bills_organization_id;
ALTER TABLE bills DROP COLUMN IF EXISTS organization_id;

ALTER TABLE bills ADD CONSTRAINT bills_branch_id_fkey
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_bills_branch_id ON bills(branch_id);

-- 3. Item_categories: add branch_id, backfill, NOT NULL, FK RESTRICT, unique(branch_id, name), drop organization_id
ALTER TABLE item_categories ADD COLUMN IF NOT EXISTS branch_id INTEGER;

UPDATE item_categories ic
SET branch_id = (SELECT id FROM branches br WHERE br.organization_id = ic.organization_id ORDER BY id LIMIT 1)
WHERE ic.branch_id IS NULL;

ALTER TABLE item_categories ALTER COLUMN branch_id SET NOT NULL;

ALTER TABLE item_categories ADD CONSTRAINT item_categories_branch_id_fkey
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_item_categories_branch_id ON item_categories(branch_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_item_categories_branch_name ON item_categories(branch_id, name);

ALTER TABLE item_categories DROP CONSTRAINT IF EXISTS item_categories_organization_id_fkey;
DROP INDEX IF EXISTS idx_item_categories_org_name;
DROP INDEX IF EXISTS idx_item_categories_organization_id;
ALTER TABLE item_categories DROP COLUMN IF EXISTS organization_id;

-- 4. Items: add branch_id, backfill, NOT NULL, FK RESTRICT, drop organization_id
ALTER TABLE items ADD COLUMN IF NOT EXISTS branch_id INTEGER;

UPDATE items i
SET branch_id = (SELECT id FROM branches br WHERE br.organization_id = i.organization_id ORDER BY id LIMIT 1)
WHERE i.branch_id IS NULL;

ALTER TABLE items ALTER COLUMN branch_id SET NOT NULL;

ALTER TABLE items ADD CONSTRAINT items_branch_id_fkey
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_items_branch_id ON items(branch_id);

ALTER TABLE items DROP CONSTRAINT IF EXISTS items_organization_id_fkey;
DROP INDEX IF EXISTS idx_items_organization_id;
ALTER TABLE items DROP COLUMN IF EXISTS organization_id;

-- ========== PHASE B: Users and branches without organization_id; drop organizations ==========

-- 5. Users: drop org FK and indexes; add global uniques on email and username; drop organization_id
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_organization_id_fkey;
DROP INDEX IF EXISTS idx_users_org_email;
DROP INDEX IF EXISTS idx_users_org_username;
DROP INDEX IF EXISTS idx_users_organization_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username);

ALTER TABLE users DROP COLUMN IF EXISTS organization_id;

-- 6. Branches: drop org FK and indexes; add global unique on code; drop organization_id
ALTER TABLE branches DROP CONSTRAINT IF EXISTS branches_organization_id_fkey;
DROP INDEX IF EXISTS idx_branches_org_code;
DROP INDEX IF EXISTS idx_branches_organization_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_branches_code ON branches(code);

ALTER TABLE branches DROP COLUMN IF EXISTS organization_id;

-- 7. Drop organizations table (drop trigger first)
DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
DROP TABLE IF EXISTS organizations;
