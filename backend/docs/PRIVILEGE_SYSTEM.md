# Privilege System Documentation

## Overview

The Bills Management API now includes a comprehensive privilege-based authorization system that allows fine-grained control over user permissions. Instead of simple admin/user roles, users can be granted specific privileges for different resources and actions.

## Database Schema

### Privileges Table
- `id`: Primary key
- `name`: Unique privilege name (e.g., 'branch.create')
- `description`: Human-readable description
- `resource`: Resource type (e.g., 'branch', 'user', 'bill', 'item')
- `action`: Action type (e.g., 'create', 'read', 'update', 'delete')
- `is_active`: Whether the privilege is active
- `created_at`, `updated_at`: Timestamps

### User Privileges Table
- `id`: Primary key
- `user_id`: Reference to users table
- `privilege_id`: Reference to privileges table
- `granted_by`: User who granted this privilege
- `granted_at`: When the privilege was granted
- `expires_at`: Optional expiration date
- `is_active`: Whether the privilege is currently active
- `created_at`, `updated_at`: Timestamps

## Default Privileges

The system comes with the following default privileges:

### Branch Management
- `branch.create` - Create new branches
- `branch.read` - View branch information
- `branch.update` - Update branch information
- `branch.delete` - Delete branches

### User Management
- `user.create` - Create new users
- `user.read` - View user information
- `user.update` - Update user information
- `user.delete` - Delete users

### Bill Management
- `bill.create` - Create new bills
- `bill.read` - View bill information
- `bill.update` - Update bill information
- `bill.delete` - Delete bills

### Item Management
- `item.create` - Create new items
- `item.read` - View item information
- `item.update` - Update item information
- `item.delete` - Delete items

### Privilege Management
- `privilege.create` - Create new privileges
- `privilege.read` - View privilege information
- `privilege.update` - Update privilege information
- `privilege.delete` - Delete privileges
- `privilege.grant` - Grant privileges to users
- `privilege.revoke` - Revoke privileges from users

## API Endpoints

### Privilege Management
- `GET /api/privileges` - List all privileges (requires `privilege.read`)
- `GET /api/privileges/:id` - Get privilege by ID (requires `privilege.read`)
- `POST /api/privileges` - Create new privilege (requires `privilege.create`)
- `PUT /api/privileges/:id` - Update privilege (requires `privilege.update`)
- `DELETE /api/privileges/:id` - Delete privilege (requires `privilege.delete`)

### User Privilege Management
- `GET /api/privileges/user/:userId` - Get user's privileges (requires `privilege.read`)
- `POST /api/privileges/grant` - Grant privilege to user (requires `privilege.grant`)
- `POST /api/privileges/revoke` - Revoke privilege from user (requires `privilege.revoke`)
- `POST /api/privileges/assign-role` - Assign role **cajero** or **administrador** to a user (requires `privilege.grant`). Body: `{ "userId": number, "role": "cajero" | "administrador" }`. Replaces all current privileges with the role's set.
- `GET /api/privileges/:id/users` - Get users with specific privilege (requires `privilege.read`)

### Roles predefinidos
- **Cajero**: solo puede crear facturas y ver facturas/ítems. Tiene: `bill.create`, `bill.read`, `item.read`. No puede editar ni borrar facturas, ni gestionar ítems/productos, clientes, sucursales (branches), categorías ni usuarios/privilegios.
- **Administrador**: puede hacer todo. Se le asignan todos los privilegios existentes en el sistema (branch.*, user.*, bill.*, item.*, client.*, privilege.*, all.*) y, además, el middleware de autorización lo trata como superusuario (no se le bloquea por falta de privilegios específicos).

### System Initialization
- `POST /api/privileges/initialize` - Initialize default privileges (requires `privilege.create`)

## Middleware Functions

### Basic Privilege Check
```javascript
const { requirePrivilege } = require('../middleware/auth');

// Require specific privilege
router.post('/branches', authenticateToken, requirePrivilege('branch', 'create'), handler);
```

### Multiple Privilege Checks
```javascript
const { requireAnyPrivilege, requireAllPrivileges } = require('../middleware/auth');

// Require any of the specified privileges
router.get('/admin', authenticateToken, requireAnyPrivilege([
  { resource: 'user', action: 'read' },
  { resource: 'branch', action: 'read' }
]), handler);

// Require all specified privileges
router.post('/super-admin', authenticateToken, requireAllPrivileges([
  { resource: 'user', action: 'create' },
  { resource: 'privilege', action: 'grant' }
]), handler);
```

### Specialized Middleware
```javascript
const { grantPrivilege, revokePrivilege } = require('../middleware/auth');

// Grant privileges (requires privilege.grant)
router.post('/grant', authenticateToken, grantPrivilege, handler);

// Revoke privileges (requires privilege.revoke)
router.post('/revoke', authenticateToken, revokePrivilege, handler);
```

## Usage Examples

### Granting Privileges
```bash
# Grant branch.create privilege to user
curl -X POST http://localhost:3000/api/privileges/grant \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 2,
    "privilegeId": 1
  }'
```

### Checking User Privileges
```bash
# Get user's privileges
curl -X GET http://localhost:3000/api/privileges/user/2 \
  -H "Authorization: Bearer <token>"
```

### Creating Custom Privileges
```bash
# Create custom privilege
curl -X POST http://localhost:3000/api/privileges \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "report.generate",
    "description": "Generate reports",
    "resource": "report",
    "action": "generate"
  }'
```

## Implementation in Routes

### Before (Simple Admin Check)
```javascript
// Old way - any authenticated user could create branches
router.post('/', authenticateToken, async (req, res) => {
  // Branch creation logic
});
```

### After (Privilege-Based)
```javascript
// New way - only users with branch.create privilege can create branches
router.post('/', authenticateToken, requirePrivilege('branch', 'create'), async (req, res) => {
  // Branch creation logic
});
```

## Admin User Setup

After running the database migration, initialize the admin user:

```bash
# Run the admin initialization script
node api/scripts/initialize-admin.js
```

This will create:
- Admin user: `admin@example.com` / `admin123`
- All default privileges granted to the admin user

**⚠️ Important**: Change the admin password after first login!

## Security Considerations

1. **Principle of Least Privilege**: Only grant the minimum privileges necessary for each user's role.

2. **Privilege Expiration**: Use the `expiresAt` field for temporary privileges.

3. **Audit Trail**: The system tracks who granted each privilege (`grantedBy` field).

4. **Soft Deletion**: Privileges are soft-deleted (`is_active = false`) rather than hard-deleted.

5. **Token Validation**: All privilege checks require valid JWT tokens.

## Migration Guide

### For Existing Applications

1. Run the database migration: `V3__Add_privilege_system.sql`
2. Initialize default privileges: `POST /api/privileges/initialize`
3. Create admin user: `node api/scripts/initialize-admin.js`
4. Update route middleware to use privilege-based authorization
5. Grant appropriate privileges to existing users

### Route Updates Required

Update these routes to use privilege-based authorization:
- Branch creation/update/deletion
- User management operations
- Bill management operations
- Item management operations

## Testing

Test the privilege system:

```bash
# Test without privilege (should fail)
curl -X POST http://localhost:3000/api/branches \
  -H "Authorization: Bearer <regular_user_token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Branch", "code": "TEST"}'

# Test with privilege (should succeed)
curl -X POST http://localhost:3000/api/branches \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Branch", "code": "TEST"}'
```

## Troubleshooting

### Common Issues

1. **"Insufficient privileges" error**: User doesn't have the required privilege
2. **"Authentication required" error**: Invalid or missing JWT token
3. **"Privilege not found" error**: Privilege doesn't exist or is inactive

### Debugging

Check user privileges:
```bash
curl -X GET http://localhost:3000/api/privileges/user/{userId} \
  -H "Authorization: Bearer <token>"
```

Check all privileges:
```bash
curl -X GET http://localhost:3000/api/privileges \
  -H "Authorization: Bearer <admin_token>"
```
