# Branch System Documentation

## Overview

The branch system (sucursal in Spanish) allows the application to support multiple company locations/branches where users can have different access levels. Users can only login to branches they have been assigned to.

## Database Schema

### Branches Table
- `id`: Primary key
- `name`: Branch name (e.g., "Main Office", "North Branch")
- `code`: Unique branch code (e.g., "MAIN", "NORTH")
- `address`: Branch address
- `phone`: Branch phone number
- `email`: Branch email
- `is_active`: Whether the branch is active
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

### User Branches Table (Junction Table)
- `id`: Primary key
- `user_id`: Foreign key to users table
- `branch_id`: Foreign key to branches table
- `is_primary`: Whether this is the user's primary branch
- `can_login`: Whether the user can login to this branch
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

## API Endpoints

### Authentication Endpoints

#### POST /api/users/login
Standard login that returns user info and accessible branches.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "user@example.com"
  },
  "accessibleBranches": [
    {
      "id": 1,
      "name": "Main Office",
      "code": "MAIN",
      "isPrimary": true,
      "canLogin": true
    }
  ],
  "token": "jwt_token_here"
}
```

#### POST /api/users/login-branch
Login to a specific branch.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "branchId": 1
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "user@example.com"
  },
  "branch": {
    "id": 1,
    "name": "Main Office",
    "code": "MAIN",
    "address": "123 Main Street",
    "phone": "+1-555-0100",
    "email": "main@company.com"
  },
  "token": "jwt_token_here"
}
```

### Branch Management Endpoints

#### GET /api/branches
Get all active branches.

**Response:**
```json
{
  "message": "Branches retrieved successfully",
  "branches": [
    {
      "id": 1,
      "name": "Main Office",
      "code": "MAIN",
      "address": "123 Main Street",
      "phone": "+1-555-0100",
      "email": "main@company.com",
      "isActive": true,
      "_count": {
        "userBranches": 5
      }
    }
  ]
}
```

#### GET /api/branches/:id
Get branch by ID.

#### GET /api/branches/code/:code
Get branch by code.

#### POST /api/branches
Create new branch (admin only).

**Request:**
```json
{
  "name": "New Branch",
  "code": "NEW",
  "address": "456 New Street",
  "phone": "+1-555-0200",
  "email": "new@company.com",
  "isActive": true
}
```

#### PUT /api/branches/:id
Update branch (admin only).

#### GET /api/branches/user/:userId
Get user's accessible branches.

#### POST /api/branches/user
Add user to branch (admin only).

**Request:**
```json
{
  "userId": 1,
  "branchId": 1,
  "isPrimary": true,
  "canLogin": true
}
```

#### PUT /api/branches/user/:userId/:branchId
Update user's branch permissions (admin only).

#### DELETE /api/branches/user/:userId/:branchId
Remove user from branch (admin only).

## Authentication Middleware

### authenticateToken
Standard JWT authentication middleware.

### authenticateBranchAccess
Branch-specific authentication middleware that:
1. Verifies JWT token
2. Checks if user can access the specified branch
3. Adds user and branch info to request object

**Usage:**
```javascript
const { authenticateBranchAccess } = require('../middleware/auth');

router.get('/some-endpoint', authenticateBranchAccess, (req, res) => {
  // req.user - authenticated user
  // req.branch - current branch
  // req.branchId - current branch ID
});
```

## Business Rules

1. **User Access**: Users can only login to branches they have been assigned to with `can_login = true`.
2. **Primary Branch**: Each user can have one primary branch (`is_primary = true`).
3. **Active Branches**: Only active branches can be used for login.
4. **Branch Codes**: Branch codes must be unique and are stored in uppercase.
5. **Cascade Deletion**: When a user or branch is deleted, their relationships are automatically removed.

## Sample Data

The migration includes sample branches:
- Main Office (MAIN)
- North Branch (NORTH)
- South Branch (SOUTH)
- East Branch (EAST)
- West Branch (WEST)

## Security Considerations

1. **JWT Tokens**: Branch-specific tokens include branch ID for additional security.
2. **Permission Checks**: All branch operations verify user permissions.
3. **Admin Routes**: Branch management routes require admin authentication (to be implemented).
4. **Input Validation**: All inputs are validated using Joi schemas.

## Migration

To apply the branch system:

1. Run the migration: `V2__Add_branch_system.sql`
2. Update Prisma schema and regenerate client
3. Restart the API server

The migration will create the necessary tables and insert sample branch data.

