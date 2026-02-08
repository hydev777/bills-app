const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { UserService } = require('../services');
const { authenticateToken, validateUserAccess } = require('../middleware/auth');
const { validateOrganization, requireOwnerOrAdmin } = require('../middleware/organization');

const userSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(50).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  organizationName: Joi.string().max(100).optional()
});

const createUserSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(50).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required()
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

const branchLoginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
  branchId: Joi.number().integer().positive().required()
});

// POST /api/users/register - Register a new user
router.post('/register', async (req, res) => {
  try {
    const { error, value } = userSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const result = await UserService.registerUser(value);
    res.status(201).json(result);
  } catch (error) {
    console.error('Error creating user:', error);
    if (error.message?.includes('User already exists') || error.message?.includes('organization')) {
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
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const result = await UserService.loginUser(value);
    res.json(result);
  } catch (error) {
    console.error('Error logging in user:', error);
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
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const result = await UserService.loginUserToBranch(value);
    res.json(result);
  } catch (error) {
    console.error('Error logging in user to branch:', error);
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
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// GET /api/users - List users in organization (auth + org)
router.get('/', authenticateToken, validateOrganization, async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const result = await UserService.getAllUsers(req.organizationId, { limit, offset });
    res.json(result);
  } catch (error) {
    console.error('Error listing users:', error);
    res.status(500).json({ error: 'Failed to list users' });
  }
});

// POST /api/users - Add user to organization (owner/admin only)
router.post('/', authenticateToken, validateOrganization, requireOwnerOrAdmin, async (req, res) => {
  try {
    const { error, value } = createUserSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const user = await UserService.createUserInOrganization(
      req.organizationId,
      value,
      req.userId
    );
    res.status(201).json({ message: 'User added to organization', user });
  } catch (err) {
    console.error('Error adding user:', err);
    if (err.message?.includes('already exists')) {
      return res.status(400).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to add user' });
  }
});

// GET /api/users/:id/bills - Get all bills for a user (same org)
router.get('/:id/bills', authenticateToken, validateOrganization, validateUserAccess, async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    const result = await UserService.getUserBills(id, req.organizationId, { limit, offset });
    res.json(result);
  } catch (error) {
    console.error('Error fetching user bills:', error);
    if (error.message === 'User not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch user bills' });
  }
});

// GET /api/users/:id/stats - Get user statistics (same org)
router.get('/:id/stats', authenticateToken, validateOrganization, validateUserAccess, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await UserService.getUserStats(id, req.organizationId);
    res.json(result);
  } catch (error) {
    console.error('Error fetching user stats:', error);
    if (error.message === 'User not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch user statistics' });
  }
});

module.exports = router;
