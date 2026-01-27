# Database Migrations with Flyway

This directory contains database migration scripts managed by Flyway.

## Directory Structure

```
migrations/
└── sql/
    └── V1__Initial_database_schema.sql
```

## Migration Naming Convention

Flyway follows a specific naming convention for migration files:

- **V{version}__{description}.sql** - Versioned migrations (e.g., V1__Initial_schema.sql)
- **U{version}__{description}.sql** - Undo migrations (optional)
- **R__{description}.sql** - Repeatable migrations

## How Migrations Work

1. **Automatic Execution**: Migrations run automatically when the `flyway` container starts
2. **Version Tracking**: Flyway maintains a `flyway_schema_history` table to track applied migrations
3. **Sequential Application**: Migrations are applied in version order
4. **Idempotent**: Already applied migrations are skipped

## Adding New Migrations

1. Create a new SQL file in the `migrations/sql/` directory
2. Follow the naming convention: `V{next_version}__{description}.sql`
3. Write your DDL/DML statements
4. Restart the services to apply the migration

Example:
```sql
-- V2__Add_user_preferences_table.sql
CREATE TABLE user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'light',
    language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Running Migrations

### Development Environment
```bash
# Start all services (migrations run automatically)
docker-compose up

# Run migrations only
docker-compose up flyway

# Run migrations with info
docker-compose run --rm flyway info
```

### Production Environment
```bash
# Validate migrations before applying
docker-compose run --rm flyway validate

# Apply migrations
docker-compose run --rm flyway migrate

# Check migration status
docker-compose run --rm flyway info
```

## Flyway Commands

The following Flyway commands are available:

- `migrate` - Apply pending migrations (default)
- `info` - Show migration status
- `validate` - Validate migrations
- `baseline` - Baseline existing database
- `repair` - Repair schema history table

## Configuration

Flyway is configured via environment variables in `docker-compose.yml`:

- `FLYWAY_URL` - Database connection URL
- `FLYWAY_USER` - Database username
- `FLYWAY_PASSWORD` - Database password
- `FLYWAY_SCHEMAS` - Target schema (default: public)
- `FLYWAY_BASELINE_ON_MIGRATE` - Create baseline for existing databases
- `FLYWAY_VALIDATE_ON_MIGRATE` - Validate migrations before applying

## Best Practices

1. **Never modify applied migrations** - Create a new migration instead
2. **Use descriptive names** - Make migration purposes clear
3. **Test migrations** - Verify on development environment first
4. **Backup before production** - Always backup before applying migrations
5. **Use transactions** - Wrap DDL statements in transactions when possible
6. **Keep migrations small** - Break large changes into smaller migrations

## Troubleshooting

### Migration Failed
If a migration fails:
1. Check the Flyway container logs: `docker-compose logs flyway`
2. Fix the issue in the migration file
3. Use `docker-compose run --rm flyway repair` if needed
4. Retry the migration

### Reset Database
To completely reset the database:
```bash
docker-compose down -v  # Remove volumes
docker-compose up       # Recreate and run migrations
```
