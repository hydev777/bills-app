-- V15__Seed_users_with_privileges.sql
-- Creates seed users with different privilege levels. Password for all: Password123
-- Safe to re-run: inserts only when user does not exist.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure users have role column (in case V4 was skipped)
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'user';

-- Ensure at least one branch exists for user_branches
INSERT INTO branches (name, code, is_active, created_at, updated_at)
SELECT 'Sucursal Principal', 'MAIN', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM branches LIMIT 1);

-- Seed users (password: Password123, hashed with bcrypt via pgcrypto)
INSERT INTO users (username, email, password_hash, role, created_at, updated_at)
SELECT 'admin', 'admin@bills.local', crypt('Password123', gen_salt('bf', 10)), 'administrador', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

INSERT INTO users (username, email, password_hash, role, created_at, updated_at)
SELECT 'cajero', 'cajero@bills.local', crypt('Password123', gen_salt('bf', 10)), 'cajero', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'cajero');

INSERT INTO users (username, email, password_hash, role, created_at, updated_at)
SELECT 'vendedor', 'vendedor@bills.local', crypt('Password123', gen_salt('bf', 10)), 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'vendedor');

-- Link seed users to the first branch (user_branches)
INSERT INTO user_branches (user_id, branch_id, is_primary, can_login, created_at, updated_at)
SELECT u.id, (SELECT id FROM branches ORDER BY id LIMIT 1), TRUE, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM users u
WHERE u.username IN ('admin', 'cajero', 'vendedor')
  AND NOT EXISTS (SELECT 1 FROM user_branches ub WHERE ub.user_id = u.id);

-- Admin: all privileges
INSERT INTO user_privileges (user_id, privilege_id, is_active, created_at, updated_at)
SELECT u.id, p.id, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM users u
CROSS JOIN privileges p
WHERE u.username = 'admin'
  AND NOT EXISTS (SELECT 1 FROM user_privileges up WHERE up.user_id = u.id AND up.privilege_id = p.id);

-- Cajero: bill.*, item.read, item.create, branch.read, user.read
INSERT INTO user_privileges (user_id, privilege_id, is_active, created_at, updated_at)
SELECT u.id, p.id, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM users u
CROSS JOIN privileges p
WHERE u.username = 'cajero'
  AND p.name IN (
    'bill.create', 'bill.read', 'bill.update', 'bill.delete',
    'item.read', 'item.create', 'item.update',
    'branch.read', 'user.read'
  )
  AND NOT EXISTS (SELECT 1 FROM user_privileges up WHERE up.user_id = u.id AND up.privilege_id = p.id);

-- Vendedor: bill.read, item.read, branch.read
INSERT INTO user_privileges (user_id, privilege_id, is_active, created_at, updated_at)
SELECT u.id, p.id, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM users u
CROSS JOIN privileges p
WHERE u.username = 'vendedor'
  AND p.name IN ('bill.read', 'item.read', 'branch.read')
  AND NOT EXISTS (SELECT 1 FROM user_privileges up WHERE up.user_id = u.id AND up.privilege_id = p.id);
