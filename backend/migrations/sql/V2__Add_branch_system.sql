-- Add branch system migration
-- This migration adds branch (sucursal) functionality and user-branch relationships

-- Create branches table (sucursal in Spanish)
CREATE TABLE IF NOT EXISTS branches (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL, -- Short code for the branch (e.g., 'MAIN', 'NYC', 'LA')
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user_branches junction table (many-to-many relationship)
-- This allows users to have access to multiple branches
CREATE TABLE IF NOT EXISTS user_branches (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    branch_id INTEGER REFERENCES branches(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE, -- Indicates if this is the user's primary branch
    can_login BOOLEAN DEFAULT TRUE, -- Permission to login to this branch
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, branch_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_branches_code ON branches(code);
CREATE INDEX IF NOT EXISTS idx_branches_is_active ON branches(is_active);
CREATE INDEX IF NOT EXISTS idx_user_branches_user_id ON user_branches(user_id);
CREATE INDEX IF NOT EXISTS idx_user_branches_branch_id ON user_branches(branch_id);
CREATE INDEX IF NOT EXISTS idx_user_branches_can_login ON user_branches(can_login);
CREATE INDEX IF NOT EXISTS idx_user_branches_is_primary ON user_branches(is_primary);

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_branches_updated_at BEFORE UPDATE ON user_branches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
