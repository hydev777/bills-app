# Bills Management API

A containerized backend application for managing bills and payments, built with Node.js, Express, PostgreSQL, and Prisma ORM.

## 🚀 Features

- **Bill Management**: Create, read, update, and delete bills (per user)
- **User Authentication**: Register and login with JWT tokens
- **Item Management**: Global catalog of items with categories
- **Bill Details**: Link items to bills with quantities and prices
- **Branches**: Manage branches (sucursales) and user–branch access
- **Privileges**: Role-based authorization (branch, user, bill, item, privilege)
- **Statistics**: Bill summaries, item/category stats
- **Containerized**: Separate Docker containers for API and database
- **Prisma ORM**: Type-safe database access
- **Database Migrations**: Flyway migrations (V1–V7)

## 📁 Project Structure

```
bills/
├── api/                           # Node.js API application
│   ├── prisma/
│   │   └── schema.prisma          # Prisma database schema
│   ├── src/
│   │   ├── config/
│   │   │   └── prisma.js          # Prisma client configuration
│   │   ├── middleware/
│   │   │   └── auth.js            # Authentication middleware
│   │   ├── routes/
│   │   │   ├── bills.js           # Bill management endpoints
│   │   │   ├── users.js           # User authentication endpoints
│   │   │   ├── items.js           # Item management endpoints
│   │   │   ├── bill-items.js      # Bill items endpoints
│   │   │   ├── branches.js        # Branch (sucursal) endpoints
│   │   │   └── privileges.js      # Privilege-based authorization
│   │   ├── services/
│   │   │   ├── BillService.js     # Bill business logic
│   │   │   ├── UserService.js     # User business logic
│   │   │   ├── ItemService.js     # Item business logic
│   │   │   ├── BillItemService.js # Bill item business logic
│   │   │   ├── ItemCategoryService.js # Item category logic
│   │   │   ├── BranchService.js   # Branch logic
│   │   │   └── PrivilegeService.js # Privilege logic
│   │   └── server.js              # Main application server
│   ├── scripts/
│   │   └── initialize-admin.js    # Admin user & privileges setup
│   ├── tests/                     # Test suite
│   │   ├── routes/                # Route tests
│   │   ├── services/              # Service tests
│   │   ├── integration/           # Integration tests
│   │   └── helpers/               # Test helpers
│   ├── Dockerfile                 # API container configuration
│   ├── package.json               # Node.js dependencies
│   └── .env                       # Environment variables
├── migrations/                    # Database migrations (Flyway)
│   ├── sql/
│   │   ├── V1__Initial_database_schema.sql
│   │   ├── V2__Add_branch_system.sql
│   │   ├── V3__Add_privilege_system.sql
│   │   ├── V4__Add_organization_system.sql   # Reverted by V7
│   │   ├── V6__Add_company_settings.sql      # Reverted by V7
│   │   └── V7__Revert_organization_system.sql # Current schema (no org/SaaS)
│   └── README.md                  # Migration documentation
├── docs/                          # Project documentation
├── docker-compose.yml             # Container orchestration
├── Makefile                       # Development commands
└── README.md                      # This file
```

## 🛠️ Quick Start

### Prerequisites

- Docker and Docker Compose installed on your system
- Git (to clone the repository)

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd bills

# Copy environment file
cp api/.env.example api/.env
```

### 2. Start the Application

```bash
# Start all services (API + Database)
docker-compose up -d

# View logs
docker-compose logs -f

# Start with pgAdmin for database management
docker-compose --profile admin up -d
```

### 3. Verify Installation

- **API Health Check**: http://localhost:3000/health
- **API Documentation**: See endpoints section below
- **pgAdmin** (if started): http://localhost:5050 (admin@example.com / admin)

## ⚙️ Project Configuration

### Environment Variables

Create a `.env` file in the `api/` directory with the following configuration:

```env
# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=bills_db
DB_USER=postgres
DB_PASSWORD=password
DATABASE_URL=postgresql://postgres:password@postgres:5432/bills_db?schema=public

# API Configuration
PORT=3000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Flyway Configuration (for migrations)
FLYWAY_URL=jdbc:postgresql://postgres:5432/bills_db
FLYWAY_USER=postgres
FLYWAY_PASSWORD=password
FLYWAY_SCHEMAS=public
FLYWAY_BASELINE_ON_MIGRATE=true
FLYWAY_VALIDATE_ON_MIGRATE=true
```

### Docker Services Configuration

The project uses the following services defined in `docker-compose.yml`:

- **postgres**: PostgreSQL 15 database
- **flyway**: Database migration service
- **api**: Node.js API application
- **pgadmin**: Optional database administration (profile: admin)

### Technology Stack

- **Backend**: Node.js 18 with Express.js
- **Database**: PostgreSQL 15 with Prisma ORM
- **Migrations**: Flyway for database schema management
- **Authentication**: JWT tokens with bcrypt password hashing
- **Testing**: Jest with Supertest
- **Containerization**: Docker & Docker Compose
- **Security**: Helmet, CORS, Rate limiting

### API Dependencies

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

### Available NPM Scripts

For detailed API scripts and development commands, see the [API README](./api/README.md#development-scripts).

**Quick API Commands:**
```bash
# API Development (run from api/ directory)
npm run dev              # Start with nodemon for development
npm start               # Start production server

# Database Operations
npm run db:generate     # Generate Prisma client
npm run db:studio       # Open Prisma Studio
```

## 📚 API Documentation

For detailed API documentation, endpoints, usage examples, and development information, see the [API README](./api/README.md).

### Quick API Reference

- **Base URL**: http://localhost:3000/api
- **Authentication**: JWT tokens required for protected endpoints
- **Content-Type**: application/json for all requests
- **Health Check**: http://localhost:3000/health

### Main Endpoints

- **Authentication**: `/api/users/register`, `/api/users/login`, `/api/users/login-branch`
- **Bills**: `/api/bills` (GET, POST, PUT, DELETE), `/api/bills/stats/summary`
- **Items**: `/api/items` (GET, POST, PUT, DELETE), `/api/items/categories`, `/api/items/:id/stats`
- **Bill Items**: `/api/bill-items` (GET, POST, PUT, DELETE), `/api/bill-items/stats/summary`
- **Branches**: `/api/branches` (GET, POST, PUT, DELETE), `/api/branches/user/:userId`
- **Privileges**: `/api/privileges` (CRUD), `/api/privileges/grant`, `/api/privileges/revoke`

## 🛠️ Development Commands (Makefile)

The project includes a comprehensive Makefile for common development tasks:

### Docker Operations
```bash
make build              # Build all containers
make up                 # Start all services in background
make up-logs            # Start all services with logs
make down               # Stop all services
make restart            # Restart all services
```

### Development
```bash
make dev                # Start in development mode with live reload
make install            # Install API dependencies
```

### Logs and Monitoring
```bash
make logs               # Show logs for all services
make logs-api           # Show API logs only
make logs-db            # Show database logs only
```

### Database Operations
```bash
make db-shell           # Connect to PostgreSQL shell
make db-reset           # Reset database (⚠️ Deletes all data)
make db-generate        # Generate Prisma client
make db-push            # Push Prisma schema to database
make db-studio          # Open Prisma Studio
```

### Admin Tools
```bash
make admin              # Start with pgAdmin
make admin-down         # Stop admin services
```

### Testing and Quality
```bash
make test               # Run tests
make lint               # Run linter (if configured)
```

### Cleanup
```bash
make clean              # Remove all containers, images, and volumes
make clean-volumes      # Remove only volumes (keeps images)
```

### Status and Health
```bash
make status             # Show status of all services
make health             # Check API health
```

### Quick Setup
```bash
make setup              # Quick setup - build and start everything
make env                # Copy environment file template
```

### Production
```bash
make prod-up            # Start in production mode
make prod-down          # Stop production services
```

## 🗄️ Database Schema

The application uses PostgreSQL with Prisma ORM. The schema is defined in `api/prisma/schema.prisma` and managed through Flyway migrations (V1–V7). The current schema does **not** use organizations or multi-tenant/SaaS; it was reverted via `V7__Revert_organization_system.sql`.

### Users Table (`users`)
- `id` (Primary Key, Auto-increment)
- `username` (Unique, VARCHAR(50))
- `email` (Unique, VARCHAR(100))
- `password_hash` (VARCHAR(255))
- `role` (VARCHAR(50), default: `user`)
- `created_at`, `updated_at` (Timestamps with auto-update triggers)

### Bills Table (`bills`)
- `id` (Primary Key, Auto-increment)
- `user_id` (Foreign Key → users.id, CASCADE DELETE)
- `title` (VARCHAR(100))
- `description` (TEXT, Optional)
- `amount` (DECIMAL(10,2))
- `created_at`, `updated_at` (Timestamps with auto-update triggers)

**Indexes**: user_id

### Item Categories Table (`item_categories`)
- `id` (Primary Key, Auto-increment)
- `name` (Unique, VARCHAR(50))
- `description` (TEXT, Optional)
- `created_at`, `updated_at` (Timestamps with auto-update triggers)

**Indexes**: name

### Items Table (`items`)
- `id` (Primary Key, Auto-increment)
- `name` (VARCHAR(100))
- `description` (TEXT, Optional)
- `unit_price` (DECIMAL(10,2))
- `category_id` (Foreign Key → item_categories.id, SET NULL)
- `created_at`, `updated_at` (Timestamps with auto-update triggers)

**Indexes**: category_id

### Bill Details Table (`bill_details`)
- `id` (Primary Key, Auto-increment)
- `bill_id` (Foreign Key → bills.id, CASCADE DELETE)
- `item_id` (Foreign Key → items.id, CASCADE DELETE)
- `quantity` (INTEGER, Default: 1)
- `unit_price` (DECIMAL(10,2))
- `total_price` (DECIMAL(10,2))
- `notes` (TEXT, Optional)
- `created_at`, `updated_at` (Timestamps with auto-update triggers)

**Constraints**: Unique(bill_id, item_id)  
**Indexes**: bill_id, item_id

### Additional Tables (V2, V3)
- **branches**: Branch (sucursal) data; `code` unique.
- **user_branches**: User–branch access (is_primary, can_login).
- **privileges**: Resource/action permissions (e.g. `branch.create`, `bill.read`).
- **user_privileges**: User–privilege assignments (granted_by, expires_at).

### Database Features
- **Triggers**: Auto-update `updated_at` timestamps on all tables
- **Cascading Deletes**: Bills and bill items removed when parent records are deleted
- **Performance**: Indexes on user_id, category_id, bill_id, item_id, and unique constraints
- **Data Integrity**: Foreign keys and unique constraints

## 🔒 Environment Variables

Create a `.env` file in the `api/` directory:

```env
# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=bills_db
DB_USER=postgres
DB_PASSWORD=password

# API Configuration
PORT=3000
NODE_ENV=development

# JWT Secret (change in production!)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

## 🐳 Docker Configuration

### Services Architecture

The application uses a multi-container setup with the following services:

1. **PostgreSQL Database** (`postgres`)
   - Image: `postgres:15-alpine`
   - Port: `5432:5432`
   - Health checks enabled
   - Persistent volume for data

2. **Flyway Migrations** (`flyway`)
   - Image: `flyway/flyway:10-alpine`
   - Runs migrations automatically on startup
   - Depends on PostgreSQL health check
   - Runs once and exits

3. **API Application** (`api`)
   - Custom Node.js 18 Alpine image
   - Port: `3000:3000`
   - Depends on PostgreSQL and Flyway completion
   - Health checks enabled
   - Source code mounted for development

4. **pgAdmin** (`pgadmin`) - Optional
   - Image: `dpage/pgadmin4:latest`
   - Port: `5050:80`
   - Only starts with `--profile admin`

### Docker Commands

```bash
# Build and start all services
docker-compose up --build

# Start in background
docker-compose up -d

# Start with database migrations
docker-compose up -d postgres flyway api

# Start with pgAdmin for database management
docker-compose --profile admin up -d

# Stop all services
docker-compose down

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v

# View logs
docker-compose logs -f api
docker-compose logs -f postgres
docker-compose logs -f flyway

# Execute commands in containers
docker-compose exec api npm install
docker-compose exec postgres psql -U postgres -d bills_db

# Check service status
docker-compose ps

# View service health
docker-compose exec api curl -f http://localhost:3000/health
```

### Dockerfile Configuration

The API uses a multi-stage Dockerfile with:
- Node.js 18 Alpine base image
- OpenSSL and libc6-compat for Prisma compatibility
- Non-root user for security
- Health checks for container monitoring
- Optimized layer caching for faster builds

## 🔍 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Change ports in docker-compose.yml
   ports:
     - "3001:3000"  # API
     - "5433:5432"  # PostgreSQL
   ```

2. **Database Connection Issues**
   ```bash
   # Check if PostgreSQL is healthy
   docker-compose ps
   
   # View PostgreSQL logs
   docker-compose logs postgres
   ```

3. **API Not Starting**
   ```bash
   # Check API logs
   docker-compose logs api
   
   # Rebuild API container
   docker-compose up --build api
   ```

### Reset Database

```bash
# Stop and remove containers with data
docker-compose down -v

# Start fresh
docker-compose up -d
```

## 🧪 Testing

For comprehensive testing information, test structure, and running tests, see the [API README](./api/README.md#testing).

### Quick Test Commands

```bash
# Run all tests
make test

# Run specific test suites
npm run test:routes        # Route tests only
npm run test:services      # Service tests only
npm run test:integration   # Integration tests only

# Run tests with coverage
npm run test:coverage
```

## 🚀 Development

### Local Development Setup

```bash
# Clone and setup
git clone <your-repo-url>
cd bills

# Quick setup with Makefile
make setup

# Or manual setup
make build
make up
```

### Development Workflow

1. **Project Setup**:
   - Use `make setup` for quick initialization
   - Use `make dev` for development with live reload
   - Use `make admin` to start with pgAdmin

2. **Database Management**:
   - Schema changes are managed through Flyway migrations (V1–V7)
   - Run migrations in order; V7 reverts the organization/SaaS system (no multi-tenant)
   - Use `make db-shell` to connect to PostgreSQL
   - Use `make db-studio` to open Prisma Studio

3. **API Development**:
   - See [API README](./api/README.md) for detailed development workflow
   - All API-related documentation is in the `api/` folder

4. **Testing & Quality**:
   - Use `make test` to run all tests
   - See [API README Testing](./api/README.md#testing) for detailed testing info

5. **Documentation**:
   - Update main README for project-level changes
   - Update API README for API-specific changes

## 📈 Production Deployment

### Security Considerations

1. **Change default passwords**:
   - PostgreSQL password
   - JWT secret
   - pgAdmin password

2. **Environment variables**:
   - Use secrets management
   - Set `NODE_ENV=production`

3. **Network security**:
   - Use reverse proxy (nginx)
   - Enable HTTPS
   - Restrict database access

### Production docker-compose.yml

```yaml
# Remove volume mounts for source code
# Remove pgAdmin service
# Use environment files or secrets
# Add resource limits
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Docker and API logs
3. Create an issue in the repository

---

**Happy Bill Managing! 💰**
