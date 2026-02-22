const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { UserService } = require('../services');
const { authenticateToken, validateUserAccess, requirePrivilege } = require('../middleware/auth');
const { validateBranch } = require('../middleware/branch');
const { logger } = require('../utils/logger');

// Allow .local and other TLDs (e.g. admin@bills.local for seed users)
const emailSchema = Joi.string().email({ tlds: { allow: false } }).required();

const userSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(50).required(),
  email: emailSchema,
  password: Joi.string().min(6).required()
});

const createUserSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(50).required(),
  email: emailSchema,
  password: Joi.string().min(6).required()
});

const loginSchema = Joi.object({
  email: emailSchema,
  password: Joi.string().required()
});

const branchLoginSchema = Joi.object({
  email: emailSchema,
  password: Joi.string().required(),
  branchId: Joi.number().integer().positive().required()
});

// POST /api/users/register - Register a new user
router.post('/register', async (req, res) => {
  try {
    const { error, value } = userSchema.validate(req.body);
    
    if (error) {
      logger.warn('Register validation error:', error.details.map(d => d.message));
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const result = await UserService.registerUser(value);
    res.status(201).json(result);
  } catch (error) {
    logger.error('Error creating user:', error.message);
    if (error.message?.includes('User already exists')) {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// POST /api/users/login - Login user
router.post('/login', async (req, res) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    
    if (error) {
      logger.warn('Login validation error:', error.details.map(d => d.message));
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const result = await UserService.loginUser(value);
    res.json(result);
  } catch (error) {
    logger.error('Error logging in user:', error.message);
    if (error.message === 'Invalid credentials') {
      return res.status(401).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to login' });
  }
});

// POST /api/users/login-branch - Login user to specific branch
router.post('/login-branch', async (req, res) => {
  try {
    const { error, value } = branchLoginSchema.validate(req.body);
    
    if (error) {
      logger.warn('Login-branch validation error:', error.details.map(d => d.message));
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const result = await UserService.loginUserToBranch(value);
    res.json(result);
  } catch (error) {
    logger.error('Error logging in user to branch:', error.message);
    if (error.message === 'Invalid credentials') {
      return res.status(401).json({ error: error.message });
    }
    if (error.message.includes('permission') || error.message.includes('not found') || error.message.includes('not active')) {
      return res.status(403).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to login to branch' });
  }
});

// GET /api/users/profile - Get user profile (requires authentication)
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await UserService.getUserById(req.userId);
    res.json({ ...user, total_bills: user._count?.bills ?? 0 });
  } catch (error) {
    logger.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// GET /api/users - List users (auth + privilege)
router.get('/', authenticateToken, requirePrivilege('user', 'read'), async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const result = await UserService.getAllUsers({ limit, offset });
    res.json(result);
  } catch (error) {
    logger.error('Error listing users:', error);
    res.status(500).json({ error: 'Failed to list users' });
  }
});

// POST /api/users - Create user (requires user.create)
router.post('/', authenticateToken, requirePrivilege('user', 'create'), async (req, res) => {
  try {
    const { error, value } = createUserSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const user = await UserService.createUser(value, req.userId);
    res.status(201).json({ message: 'User created', user });
  } catch (err) {
    logger.error('Error adding user:', err);
    if (err.message?.includes('already exists')) {
      return res.status(400).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to add user' });
  }
});

// GET /api/users/:id/bills - Get all bills for a user in current branch. Requires X-Branch-Id
router.get('/:id/bills', authenticateToken, validateBranch, validateUserAccess, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    const result = await UserService.getUserBills(id, req.branchId, { limit, offset });
    res.json(result);
  } catch (error) {
    logger.error('Error fetching user bills:', error);
    if (error.message === 'User not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch user bills' });
  }
});

// GET /api/users/:id/stats - Get user statistics (branch-scoped). Requires X-Branch-Id
router.get('/:id/stats', authenticateToken, validateBranch, validateUserAccess, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await UserService.getUserStats(id, req.branchId);
    res.json(result);
  } catch (error) {
    logger.error('Error fetching user stats:', error);
    if (error.message === 'User not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch user statistics' });
  }
});

module.exports = router;
