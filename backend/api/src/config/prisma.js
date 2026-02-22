const path = require('path');
const fs = require('fs');
const { Client } = require('pg');
const { PrismaClient } = require('@prisma/client');

/** Strip leading comment lines from a statement. */
function stripLeadingComments(stmt) {
  let s = stmt.trim();
  while (s.startsWith('--')) {
    const nl = s.indexOf('\n');
    if (nl === -1) return '';
    s = s.slice(nl + 1).trim();
  }
  return s;
}

/** Split SQL into single statements, respecting $$...$$ and -- line comments. */
function splitSqlStatements(sql) {
  const statements = [];
  let current = '';
  let inDollarQuote = false;
  let inLineComment = false;
  let i = 0;
  while (i < sql.length) {
    if (inLineComment) {
      if (sql[i] === '\n' || sql[i] === '\r') {
        inLineComment = false;
        current += sql[i];
      } else {
        current += sql[i];
      }
      i++;
      continue;
    }
    if (!inDollarQuote && i + 1 < sql.length && sql[i] === '-' && sql[i + 1] === '-') {
      inLineComment = true;
      current += '--';
      i += 2;
      continue;
    }
    if (inDollarQuote) {
      if (sql.slice(i, i + 2) === '$$') {
        inDollarQuote = false;
        current += '$$';
        i += 2;
        continue;
      }
      current += sql[i];
      i++;
      continue;
    }
    if (sql.slice(i, i + 2) === '$$') {
      inDollarQuote = true;
      current += '$$';
      i += 2;
      continue;
    }
    if (sql[i] === ';') {
      const raw = current.trim();
      const stmt = stripLeadingComments(raw);
      if (stmt) statements.push(stmt);
      current = '';
      i++;
      continue;
    }
    current += sql[i];
    i++;
  }
  const raw = current.trim();
  const stmt = stripLeadingComments(raw);
  if (stmt) statements.push(stmt);
  return statements;
}

// .env next to package.json (api folder)
const envPath = path.resolve(__dirname, '..', '..', '.env');

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const raw = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '');
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq > 0) {
      const key = trimmed.slice(0, eq).trim();
      const value = trimmed.slice(eq + 1).trim();
      if (key) process.env[key] = value;
    }
  }
}

require('dotenv').config({ path: envPath });
if (!process.env.DATABASE_URL) loadEnvFile(envPath);

if (!process.env.DATABASE_URL) {
  const defaultEnv = [
    'DATABASE_URL=postgresql://postgres:password@localhost:5432/bills_db?schema=public',
    'PORT=3000',
    'NODE_ENV=development',
    'JWT_SECRET=your-super-secret-jwt-key-change-this-in-production',
  ].join('\n');
  try {
    fs.writeFileSync(envPath, defaultEnv, 'utf8');
    loadEnvFile(envPath);
    console.log('✅ Created', envPath, 'with default DATABASE_URL');
  } catch (e) {
    console.error('❌ DATABASE_URL not set. Create backend/api/.env with:');
    console.error('   DATABASE_URL=postgresql://postgres:password@localhost:5432/bills_db?schema=public');
    console.error('   Path tried:', envPath);
    throw new Error('DATABASE_URL is required. Add it to backend/api/.env');
  }
}

if (!process.env.DATABASE_URL) {
  console.error('❌ DATABASE_URL not set. Path tried:', envPath);
  throw new Error('DATABASE_URL is required. Add it to backend/api/.env');
}

// Create a single instance of Prisma Client
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
  errorFormat: 'pretty',
});

/**
 * Build connection URL for the default 'postgres' database and get target DB name.
 */
function getDefaultDbUrlAndTargetName() {
  const url = process.env.DATABASE_URL;
  if (!url) return null;
  const m = url.match(/^(postgresql:\/\/[^/]+)\/([^/?]+)(\?.*)?$/);
  if (!m) return null;
  return {
    connectionStringForDefaultDb: `${m[1]}/postgres${m[3] || ''}`,
    databaseName: m[2],
  };
}

/**
 * Run Flyway-style migrations from backend/migrations/sql (V1__, V2__, ...).
 */
async function runMigrations(connectionString) {
  const migrationsDir = path.resolve(__dirname, '..', '..', '..', 'migrations', 'sql');
  if (!fs.existsSync(migrationsDir)) {
    throw new Error(`Migrations directory not found: ${migrationsDir}`);
  }
  const files = fs.readdirSync(migrationsDir)
    .filter((f) => /^V\d+__.*\.sql$/i.test(f))
    .sort((a, b) => {
      const nA = parseInt(a.match(/^V(\d+)/i)[1], 10);
      const nB = parseInt(b.match(/^V(\d+)/i)[1], 10);
      return nA - nB;
    });
  const client = new Client({ connectionString });
  await client.connect();
  const applied = [];
  try {
    console.log('📦 Running migrations (each version will be applied):');
    for (const file of files) {
      const versionMatch = file.match(/^V(\d+)__(.+)\.sql$/i);
      const version = versionMatch ? `V${versionMatch[1]}` : file;
      const name = versionMatch ? versionMatch[2].replace(/_/g, ' ') : file;
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '');
      const statements = splitSqlStatements(sql);
      console.log(`   [${version}] ${name} (${statements.length} statements)...`);
      for (const stmt of statements) {
        if (!stmt) continue;
        try {
          await client.query(stmt);
        } catch (err) {
          console.error(`❌ Failed in ${file}:`, err.message);
          throw err;
        }
      }
      applied.push(version);
      console.log(`   [${version}] ✓ applied`);
    }
    console.log('✅ Migrations applied: ' + applied.join(', '));
  } finally {
    await client.end();
  }
}

/**
 * Create the database (e.g. bills_db) if it doesn't exist, then run migrations
 * from backend/migrations/sql (V1, V2, ...) in order. Migrations use IF NOT EXISTS
 * / DROP IF EXISTS so re-running is safe and won't break existing data.
 */
async function ensureDatabaseAndSchema() {
  const parsed = getDefaultDbUrlAndTargetName();
  if (!parsed) {
    throw new Error('Could not parse DATABASE_URL');
  }
  const { connectionStringForDefaultDb, databaseName } = parsed;
  const defaultDbClient = new Client({ connectionString: connectionStringForDefaultDb });
  try {
    await defaultDbClient.connect();
    const r = await defaultDbClient.query(
      "SELECT 1 FROM pg_database WHERE datname = $1",
      [databaseName]
    );
    if (r.rows.length === 0) {
      console.log(`📦 Creating database "${databaseName}"...`);
      await defaultDbClient.query(`CREATE DATABASE "${databaseName}"`);
      console.log(`✅ Database "${databaseName}" created`);
    }
  } finally {
    await defaultDbClient.end();
  }
  // Migrations run in connectDB after connect
}

// Connect to the database
const connectDB = async () => {
  try {
    await prisma.$connect();
    console.log('✅ Connected to PostgreSQL database via Prisma');
  } catch (error) {
    const dbDoesNotExist =
      error.code === 'P1003' ||
      error.errorCode === 'P1003' ||
      (error.message && error.message.includes('does not exist on the database server'));
    if (dbDoesNotExist) {
      console.log('Database does not exist, creating and running schema...');
      try {
        await ensureDatabaseAndSchema();
        await prisma.$connect();
        console.log('✅ Connected to PostgreSQL database via Prisma');
      } catch (createErr) {
        console.error('❌ Failed to create database or run schema:', createErr);
        throw createErr;
      }
    } else {
      console.error('❌ Database connection failed:', error);
      throw error;
    }
  }
  // Run migrations on every startup so every version is applied (idempotent)
  await runMigrations(process.env.DATABASE_URL);
};

// Graceful shutdown
const disconnectDB = async () => {
  try {
    await prisma.$disconnect();
    console.log('✅ Disconnected from PostgreSQL database');
  } catch (error) {
    console.error('❌ Error disconnecting from database:', error);
  }
};

// Handle process termination
process.on('beforeExit', async () => {
  await disconnectDB();
});

process.on('SIGINT', async () => {
  await disconnectDB();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await disconnectDB();
  process.exit(0);
});

module.exports = {
  prisma,
  connectDB,
  disconnectDB
};
