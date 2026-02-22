-- V3__Add_privilege_system.sql
-- Migration to add privilege-based authorization system

-- Create privileges table
CREATE TABLE IF NOT EXISTS privileges (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure unique combination of resource and action
    CONSTRAINT unique_resource_action UNIQUE (resource, action)
);

-- Create indexes for privileges table
CREATE INDEX IF NOT EXISTS idx_privileges_resource ON privileges(resource);
CREATE INDEX IF NOT EXISTS idx_privileges_action ON privileges(action);
CREATE INDEX IF NOT EXISTS idx_privileges_is_active ON privileges(is_active);

-- Create user_privileges table (junction table)
CREATE TABLE IF NOT EXISTS user_privileges (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    privilege_id INTEGER NOT NULL,
    granted_by INTEGER,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_user_privileges_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_privileges_privilege_id FOREIGN KEY (privilege_id) REFERENCES privileges(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_privileges_granted_by FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL,
    
    -- Ensure unique combination of user and privilege
    CONSTRAINT unique_user_privilege UNIQUE (user_id, privilege_id)
);

-- Create indexes for user_privileges table
CREATE INDEX IF NOT EXISTS idx_user_privileges_user_id ON user_privileges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_privileges_privilege_id ON user_privileges(privilege_id);
CREATE INDEX IF NOT EXISTS idx_user_privileges_is_active ON user_privileges(is_active);
CREATE INDEX IF NOT EXISTS idx_user_privileges_expires_at ON user_privileges(expires_at);

-- Insert default privileges (skip if already exist to allow re-run)
INSERT INTO privileges (name, description, resource, action)
SELECT name, description, resource, action FROM (VALUES
-- Branch privileges
('branch.create', 'Create new branches', 'branch', 'create'),
('branch.read', 'View branch information', 'branch', 'read'),
('branch.update', 'Update branch information', 'branch', 'update'),
('branch.delete', 'Delete branches', 'branch', 'delete'),

-- User privileges
('user.create', 'Create new users', 'user', 'create'),
('user.read', 'View user information', 'user', 'read'),
('user.update', 'Update user information', 'user', 'update'),
('user.delete', 'Delete users', 'user', 'delete'),

-- Bill privileges
('bill.create', 'Create new bills', 'bill', 'create'),
('bill.read', 'View bill information', 'bill', 'read'),
('bill.update', 'Update bill information', 'bill', 'update'),
('bill.delete', 'Delete bills', 'bill', 'delete'),

-- Item privileges
('item.create', 'Create new items', 'item', 'create'),
('item.read', 'View item information', 'item', 'read'),
('item.update', 'Update item information', 'item', 'update'),
('item.delete', 'Delete items', 'item', 'delete'),

-- Privilege management
('privilege.create', 'Create new privileges', 'privilege', 'create'),
('privilege.read', 'View privilege information', 'privilege', 'read'),
('privilege.update', 'Update privilege information', 'privilege', 'update'),
('privilege.delete', 'Delete privileges', 'privilege', 'delete'),
('privilege.grant', 'Grant privileges to users', 'privilege', 'grant'),
('privilege.revoke', 'Revoke privileges from users', 'privilege', 'revoke')
) AS v(name, description, resource, action)
WHERE NOT EXISTS (SELECT 1 FROM privileges LIMIT 1);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to privileges table (DROP IF EXISTS so re-run is safe)
DROP TRIGGER IF EXISTS update_privileges_updated_at ON privileges;
DROP TRIGGER IF EXISTS update_user_privileges_updated_at ON user_privileges;
CREATE TRIGGER update_privileges_updated_at 
    BEFORE UPDATE ON privileges 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to user_privileges table
CREATE TRIGGER update_user_privileges_updated_at 
    BEFORE UPDATE ON user_privileges 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
