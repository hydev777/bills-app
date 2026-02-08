# Bills Management API

A Node.js REST API for managing bills, users, and items with JWT authentication, built with Express.js, PostgreSQL, and Prisma ORM.

## 🚀 Features

- **User Authentication**: JWT-based auth with bcrypt; register, login, login-branch
- **Bill Management**: CRUD for bills (per user) with filtering and pagination
- **Item Management**: Global catalog of items and categories
- **Bill Details**: Many-to-many bills–items with quantities and prices
- **Branches & Privileges**: Branches (sucursales), user–branch access, privilege-based authorization
- **Statistics**: Bill summaries, item/category stats
- **Input Validation**: Joi validation for all endpoints
- **Security**: Helmet, CORS, rate limiting
- **Testing**: Jest and Supertest

## 📁 API Structure

```
api/
├── src/
│   ├── config/
│   │   └── prisma.js          # Prisma client configuration
│   ├── middleware/
│   │   └── auth.js            # JWT authentication middleware
│   ├── routes/
│   │   ├── bills.js           # Bill management endpoints
│   │   ├── users.js           # User authentication endpoints
│   │   ├── items.js           # Item management endpoints
│   │   ├── bill-items.js      # Bill items endpoints
│   │   ├── branches.js        # Branch (sucursal) endpoints
│   │   └── privileges.js      # Privilege-based authorization
│   ├── services/
│   │   ├── BillService.js     # Bill business logic
│   │   ├── UserService.js     # User business logic
│   │   ├── ItemService.js     # Item business logic
│   │   ├── BillItemService.js # Bill item business logic
│   │   ├── ItemCategoryService.js # Item category logic
│   │   ├── BranchService.js   # Branch logic
│   │   └── PrivilegeService.js # Privilege logic
│   └── server.js              # Main application server
├── scripts/
│   └── initialize-admin.js    # Admin user & privileges setup
├── tests/                     # Test suite
│   ├── routes/                # Route tests
│   ├── services/              # Service tests
│   ├── integration/           # Integration tests
│   └── helpers/               # Test helpers
├── prisma/
│   └── schema.prisma          # Database schema (no organizations/SaaS)
├── package.json               # Dependencies and scripts
└── Dockerfile                 # Container configuration
```

## 🛠️ Quick Start

### Prerequisites

- Node.js 18+ 
- PostgreSQL database (or use Docker)
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Generate Prisma client
npm run db:generate

# Start development server
npm run dev
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the `api/` directory:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bills_db
DB_USER=postgres
DB_PASSWORD=password
DATABASE_URL=postgresql://postgres:password@localhost:5432/bills_db?schema=public

# API Configuration
PORT=3000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

### Technology Stack

- **Runtime**: Node.js 18
- **Framework**: Express.js 4.18
- **Database**: PostgreSQL 15 with Prisma ORM 5.6
- **Authentication**: JWT with bcryptjs
- **Validation**: Joi 17.9
- **Testing**: Jest 29.6 with Supertest 6.3
- **Security**: Helmet, CORS, express-rate-limit

### Dependencies

```json
{
  "dependencies": {
    "express": "^4.18.2",
    "@prisma/client": "^5.6.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.10.0",
    "joi": "^17.9.2",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "prisma": "^5.6.0",
    "nodemon": "^3.0.1",
    "jest": "^29.6.2",
    "supertest": "^6.3.3"
  }
}
```

## 📚 API Endpoints

### Base URL
```
http://localhost:3000/api
```

### Authentication

```http
POST /api/users/register    # Register a new user (public)
POST /api/users/login       # Login user
POST /api/users/login-branch # Login to specific branch
GET  /api/users/profile     # Get user profile (requires token)
```

### Bills Management

```http
GET    /api/bills                    # Get all bills (with filtering)
GET    /api/bills/:id               # Get specific bill
POST   /api/bills                   # Create new bill
PUT    /api/bills/:id               # Update bill
DELETE /api/bills/:id               # Delete bill
GET    /api/bills/stats/summary     # Get bill statistics
```

### Items Management

```http
GET    /api/items                     # Get all items
GET    /api/items/:id                 # Get specific item
GET    /api/items/:id/stats           # Item usage statistics
GET    /api/items/categories          # List categories
POST   /api/items/categories          # Create category
GET    /api/items/categories/:id      # Get category
PUT    /api/items/categories/:id      # Update category
DELETE /api/items/categories/:id      # Delete category
POST   /api/items                     # Create new item
PUT    /api/items/:id                 # Update item
DELETE /api/items/:id                 # Delete item
```

### Bill Items Management

Request body for **POST /api/bill-items**: `bill_id` (required), `item_id` (required), `quantity` (optional, default: 1), `unit_price` (optional), `notes` (optional).

```http
GET    /api/bill-items                # Get all bill items
GET    /api/bill-items/:id            # Get specific bill item
GET    /api/bill-items/bill/:bill_id  # Items for a bill
GET    /api/bill-items/item/:item_id  # Bills containing an item
GET    /api/bill-items/stats/summary  # Bill-item statistics
POST   /api/bill-items                # Create new bill item (can include quantity)
PUT    /api/bill-items/:id            # Update bill item
DELETE /api/bill-items/:id            # Delete bill item
```

### Branches & Privileges

```http
GET    /api/branches                  # List branches
GET    /api/branches/:id              # Get branch
GET    /api/branches/user/:userId     # User's branches
POST   /api/branches                  # Create branch (privilege)
PUT    /api/branches/:id              # Update branch (privilege)
GET    /api/privileges                # List privileges
GET    /api/privileges/user/:userId   # User's privileges
POST   /api/privileges/grant          # Grant privilege (privilege)
POST   /api/privileges/revoke         # Revoke privilege (privilege)
```

### Query Parameters for GET /api/bills

Bills are filtered by the authenticated user (from JWT). Optional:

- `limit`: Limit results (default: 50)
- `offset`: Offset for pagination (default: 0)

## 🔧 API Usage Examples

### Register a User

```bash
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "securepassword123"
  }'
```

**Response:**
```json
{
  "message": "User created successfully",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "role": "user",
    "createdAt": "..."
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Login User

```bash
curl -X POST http://localhost:3000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "securepassword123"
  }'
```

### Create a Bill

```bash
curl -X POST http://localhost:3000/api/bills \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Electric Bill",
    "description": "Monthly electricity bill",
    "amount": 125.50
  }'
```

### Get Bills with Filtering

```bash
# Get bills with pagination (filtered by authenticated user)
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  "http://localhost:3000/api/bills?limit=10&offset=0"
```

### Get Bill Statistics

```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  "http://localhost:3000/api/bills/stats/summary"
```
Statistics are for the authenticated user.

### Add item to bill (with quantity)

```bash
curl -X POST http://localhost:3000/api/bill-items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-Organization-Id: YOUR_ORG_ID" \
  -d '{
    "bill_id": 1,
    "item_id": 1,
    "quantity": 3,
    "unit_price": 10.50,
    "notes": "Optional notes"
  }'
```
- `quantity`: number of units (optional; default is 1).
- `unit_price`: optional; if omitted, the item's default unit price is used.
- `notes`: optional.

## 🗄️ Database Schema

The API uses PostgreSQL with Prisma ORM. The schema is in `prisma/schema.prisma`. The current schema does **not** use organizations or multi-tenant/SaaS (reverted via migration V7).

### Models

- **User**: Auth and profile; `username`, `email` unique globally; `role`
- **Bill**: Bills per user (`user_id`); title, description, amount
- **Item**: Global catalog; `category_id` → ItemCategory
- **ItemCategory**: Global categories; `name` unique
- **BillItem**: Bills–items many-to-many (quantity, unit_price, total_price)
- **Branch**: Branches (sucursales); `code` unique
- **UserBranch**: User–branch access (is_primary, can_login)
- **Privilege** / **UserPrivilege**: Resource/action permissions and assignments

### Key Features

- **Cascading Deletes**: Bills and bill items removed when parents are deleted
- **Indexes**: user_id, category_id, bill_id, item_id; unique constraints
- **Timestamps**: created_at, updated_at with triggers

## 🧪 Testing

### Test Structure

```
tests/
├── routes/                # API endpoint tests
│   ├── bills.test.js
│   ├── users.test.js
│   ├── items.test.js
│   └── bill-items.test.js
├── services/              # Business logic tests
│   ├── BillService.test.js
│   ├── UserService.test.js
│   ├── ItemService.test.js
│   ├── BillItemService.test.js
│   └── ItemCategoryService.test.js
├── integration/           # Integration tests
│   └── api.test.js
├── helpers/               # Test utilities
│   └── testHelpers.js
├── config/                # Test configuration
│   └── test.env
├── jest.config.js         # Jest configuration
└── setup.js              # Test setup
```

### Running Tests

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:routes        # Route tests only
npm run test:services      # Service tests only
npm run test:integration   # Integration tests only

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

### Test Categories

1. **Unit Tests** (Services)
   - Test business logic in isolation
   - Mock external dependencies
   - Fast execution

2. **Integration Tests** (Routes)
   - Test API endpoints
   - Use test database
   - End-to-end request/response testing

3. **API Tests** (Integration)
   - Full API workflow testing
   - Authentication flows
   - Error handling

## 🛠️ Development Scripts

```bash
# Development
npm run dev              # Start with nodemon for development
npm start               # Start production server

# Database
npm run db:generate     # Generate Prisma client
npm run db:push         # Push schema changes to database
npm run db:migrate      # Run Prisma migrations
npm run db:studio       # Open Prisma Studio

# Testing
npm test                # Run all tests
npm run test:watch      # Run tests in watch mode
npm run test:coverage   # Run tests with coverage
npm run test:routes     # Run only route tests
npm run test:services   # Run only service tests
npm run test:integration # Run only integration tests
```

## 🚀 Development Workflow

### 1. Database Changes
```bash
# Update schema
vim prisma/schema.prisma

# Generate Prisma client
npm run db:generate

# Apply schema changes
npm run db:push
```

### 2. API Development
```bash
# Add new routes
vim src/routes/new-feature.js

# Implement business logic
vim src/services/NewFeatureService.js

# Add validation schemas using Joi
```

### 3. Testing
```bash
# Write tests for new features
vim tests/routes/new-feature.test.js

# Run tests before committing
npm test
```

### 4. Code Quality
- Maintain test coverage above 80%
- Use JSDoc comments for functions
- Follow consistent error handling patterns
- Validate all inputs with Joi schemas

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt for password security
- **Input Validation**: Joi schema validation for all inputs
- **Rate Limiting**: Prevent API abuse
- **CORS**: Configured for cross-origin requests
- **Helmet**: Security headers for Express
- **SQL Injection Protection**: Prisma ORM prevents SQL injection

## 📈 Performance

- **Database Indexes**: Optimized for common query patterns
- **Connection Pooling**: Prisma manages database connections
- **Response Compression**: Express compression middleware
- **Caching**: Strategic caching for frequently accessed data

## 🐛 Error Handling

The API uses consistent error handling with the following structure:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error information",
  "code": "ERROR_CODE"
}
```

### Common Error Codes

- `VALIDATION_ERROR`: Input validation failed
- `AUTHENTICATION_ERROR`: Invalid or missing authentication
- `AUTHORIZATION_ERROR`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `DUPLICATE_ERROR`: Resource already exists
- `DATABASE_ERROR`: Database operation failed

## 📚 Additional Resources

- [Prisma Documentation](https://www.prisma.io/docs)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
- [JWT Authentication](https://jwt.io/introduction)
- [Jest Testing Framework](https://jestjs.io/docs/getting-started)

---

**Happy API Development! 🚀**
