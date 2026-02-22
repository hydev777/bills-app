const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// Load .env from api/ directory (parent of src/)
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { logger, requestLogger } = require('./utils/logger');
const billRoutes = require('./routes/bills');
const userRoutes = require('./routes/users');
const itemRoutes = require('./routes/items');
const billItemRoutes = require('./routes/bill-items');
const itbisRateRoutes = require('./routes/itbis-rates');
const clientRoutes = require('./routes/clients');
const branchRoutes = require('./routes/branches');
const privilegeRoutes = require('./routes/privileges');
const { connectDB } = require('./config/prisma');
const { authenticateToken } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging (method, path, status, duration)
app.use(requestLogger);

// Routes
app.use('/api/bills', billRoutes);
app.use('/api/users', userRoutes);
app.use('/api/items', itemRoutes);
app.use('/api/bill-items', billItemRoutes);
app.use('/api/itbis-rates', itbisRateRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/branches', branchRoutes);
app.use('/api/privileges', privilegeRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'bills-api'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err.message, err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
const startServer = async () => {
  try {
    await connectDB();
    app.listen(PORT, () => {
      logger.info('Server running on port', PORT);
      logger.info('Health check: http://localhost:' + PORT + '/health');
    });
  } catch (error) {
    logger.error('Failed to start server:', error.message, error.stack);
    process.exit(1);
  }
};

startServer();

module.exports = app;
