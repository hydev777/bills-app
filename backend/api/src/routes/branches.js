const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { BranchService } = require('../services');
const { authenticateToken, authenticateBranchAccess, requirePrivilege } = require('../middleware/auth');

// Validation schemas
const branchSchema = Joi.object({
  name: Joi.string().min(2).max(100).required(),
  code: Joi.string().alphanum().min(2).max(20).required(),
  address: Joi.string().max(500).allow(''),
  phone: Joi.string().max(20).allow(''),
  email: Joi.string().email().allow(''),
  isActive: Joi.boolean().default(true)
});

const userBranchSchema = Joi.object({
  userId: Joi.number().integer().positive().required(),
  branchId: Joi.number().integer().positive().required(),
  isPrimary: Joi.boolean().default(false),
  canLogin: Joi.boolean().default(true)
});

const updateUserBranchSchema = Joi.object({
  isPrimary: Joi.boolean(),
  canLogin: Joi.boolean()
});

// GET /api/branches - Get all active branches
router.get('/', authenticateToken, async (req, res) => {
  try {
    const branches = await BranchService.getAllBranches();
    res.json({
      message: 'Branches retrieved successfully',
      branches
    });
  } catch (error) {
    console.error('Error fetching branches:', error);
    res.status(500).json({ error: 'Failed to fetch branches' });
  }
});

// GET /api/branches/:id - Get branch by ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const branch = await BranchService.getBranchById(id);
    
    if (!branch) {
      return res.status(404).json({ error: 'Branch not found' });
    }
    
    res.json({
      message: 'Branch retrieved successfully',
      branch
    });
  } catch (error) {
    console.error('Error fetching branch:', error);
    res.status(500).json({ error: 'Failed to fetch branch' });
  }
});

// GET /api/branches/code/:code - Get branch by code
router.get('/code/:code', authenticateToken, async (req, res) => {
  try {
    const { code } = req.params;
    const branch = await BranchService.getBranchByCode(code);
    
    if (!branch) {
      return res.status(404).json({ error: 'Branch not found' });
    }
    
    res.json({
      message: 'Branch retrieved successfully',
      branch
    });
  } catch (error) {
    console.error('Error fetching branch by code:', error);
    res.status(500).json({ error: 'Failed to fetch branch' });
  }
});

// POST /api/branches - Create new branch (requires branch.create privilege)
router.post('/', authenticateToken, requirePrivilege('branch', 'create'), async (req, res) => {
  try {
    const { error, value } = branchSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const branch = await BranchService.createBranch(value);
    res.status(201).json({
      message: 'Branch created successfully',
      branch
    });
  } catch (error) {
    console.error('Error creating branch:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Branch code already exists' });
    }
    res.status(500).json({ error: 'Failed to create branch' });
  }
});

// PUT /api/branches/:id - Update branch (requires branch.update privilege)
router.put('/:id', authenticateToken, requirePrivilege('branch', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = branchSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const branch = await BranchService.updateBranch(id, value);
    res.json({
      message: 'Branch updated successfully',
      branch
    });
  } catch (error) {
    console.error('Error updating branch:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Branch not found' });
    }
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Branch code already exists' });
    }
    res.status(500).json({ error: 'Failed to update branch' });
  }
});

// GET /api/branches/user/:userId - Get user's accessible branches
router.get('/user/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Check if user is accessing their own branches or has admin rights
    if (parseInt(userId) !== req.userId) {
      // TODO: Add admin role check here
      return res.status(403).json({ 
        error: 'Forbidden', 
        message: 'You can only access your own branches' 
      });
    }
    
    const userBranches = await BranchService.getUserBranches(userId);
    res.json({
      message: 'User branches retrieved successfully',
      branches: userBranches.map(ub => ({
        id: ub.branch.id,
        name: ub.branch.name,
        code: ub.branch.code,
        address: ub.branch.address,
        phone: ub.branch.phone,
        email: ub.branch.email,
        isActive: ub.branch.isActive,
        isPrimary: ub.isPrimary,
        canLogin: ub.canLogin,
        createdAt: ub.createdAt
      }))
    });
  } catch (error) {
    console.error('Error fetching user branches:', error);
    res.status(500).json({ error: 'Failed to fetch user branches' });
  }
});

// POST /api/branches/user - Add user to branch (requires branch.update privilege)
router.post('/user', authenticateToken, requirePrivilege('branch', 'update'), async (req, res) => {
  try {
    const { error, value } = userBranchSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const userBranch = await BranchService.addUserToBranch(
      value.userId, 
      value.branchId, 
      { 
        isPrimary: value.isPrimary, 
        canLogin: value.canLogin 
      }
    );
    
    res.status(201).json({
      message: 'User added to branch successfully',
      userBranch
    });
  } catch (error) {
    console.error('Error adding user to branch:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'User is already assigned to this branch' });
    }
    res.status(500).json({ error: 'Failed to add user to branch' });
  }
});

// PUT /api/branches/user/:userId/:branchId - Update user's branch permissions (requires branch.update privilege)
router.put('/user/:userId/:branchId', authenticateToken, requirePrivilege('branch', 'update'), async (req, res) => {
  try {
    const { userId, branchId } = req.params;
    const { error, value } = updateUserBranchSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const userBranch = await BranchService.updateUserBranchPermissions(
      userId, 
      branchId, 
      value
    );
    
    res.json({
      message: 'User branch permissions updated successfully',
      userBranch
    });
  } catch (error) {
    console.error('Error updating user branch permissions:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'User-branch relationship not found' });
    }
    res.status(500).json({ error: 'Failed to update user branch permissions' });
  }
});

// DELETE /api/branches/user/:userId/:branchId - Remove user from branch (requires branch.update privilege)
router.delete('/user/:userId/:branchId', authenticateToken, requirePrivilege('branch', 'update'), async (req, res) => {
  try {
    const { userId, branchId } = req.params;
    
    const result = await BranchService.removeUserFromBranch(userId, branchId);
    res.json({
      message: 'User removed from branch successfully',
      ...result
    });
  } catch (error) {
    console.error('Error removing user from branch:', error);
    res.status(500).json({ error: 'Failed to remove user from branch' });
  }
});

module.exports = router;

