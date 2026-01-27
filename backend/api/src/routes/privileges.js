const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { PrivilegeService } = require('../services');
const { authenticateToken, requirePrivilege, grantPrivilege, revokePrivilege } = require('../middleware/auth');

// Validation schemas
const privilegeSchema = Joi.object({
  name: Joi.string().min(2).max(50).required(),
  description: Joi.string().max(255).allow(''),
  resource: Joi.string().min(2).max(50).required(),
  action: Joi.string().min(2).max(50).required(),
  isActive: Joi.boolean().default(true)
});

const grantPrivilegeSchema = Joi.object({
  userId: Joi.number().integer().positive().required(),
  privilegeId: Joi.number().integer().positive().required(),
  expiresAt: Joi.date().iso().allow(null).optional()
});

const revokePrivilegeSchema = Joi.object({
  userId: Joi.number().integer().positive().required(),
  privilegeId: Joi.number().integer().positive().required()
});

// GET /api/privileges - Get all privileges (requires privilege.read)
router.get('/', authenticateToken, requirePrivilege('privilege', 'read'), async (req, res) => {
  try {
    const privileges = await PrivilegeService.getAllPrivileges();
    res.json({
      message: 'Privileges retrieved successfully',
      privileges
    });
  } catch (error) {
    console.error('Error fetching privileges:', error);
    res.status(500).json({ error: 'Failed to fetch privileges' });
  }
});

// GET /api/privileges/:id - Get privilege by ID (requires privilege.read)
router.get('/:id', authenticateToken, requirePrivilege('privilege', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const privilege = await PrivilegeService.getPrivilegeById(id);
    
    if (!privilege) {
      return res.status(404).json({ error: 'Privilege not found' });
    }
    
    res.json({
      message: 'Privilege retrieved successfully',
      privilege
    });
  } catch (error) {
    console.error('Error fetching privilege:', error);
    res.status(500).json({ error: 'Failed to fetch privilege' });
  }
});

// POST /api/privileges - Create new privilege (requires privilege.create)
router.post('/', authenticateToken, requirePrivilege('privilege', 'create'), async (req, res) => {
  try {
    const { error, value } = privilegeSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const privilege = await PrivilegeService.createPrivilege(value);
    res.status(201).json({
      message: 'Privilege created successfully',
      privilege
    });
  } catch (error) {
    console.error('Error creating privilege:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Privilege name already exists' });
    }
    res.status(500).json({ error: 'Failed to create privilege' });
  }
});

// PUT /api/privileges/:id - Update privilege (requires privilege.update)
router.put('/:id', authenticateToken, requirePrivilege('privilege', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = privilegeSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const privilege = await PrivilegeService.updatePrivilege(id, value);
    res.json({
      message: 'Privilege updated successfully',
      privilege
    });
  } catch (error) {
    console.error('Error updating privilege:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Privilege not found' });
    }
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Privilege name already exists' });
    }
    res.status(500).json({ error: 'Failed to update privilege' });
  }
});

// DELETE /api/privileges/:id - Delete privilege (requires privilege.delete)
router.delete('/:id', authenticateToken, requirePrivilege('privilege', 'delete'), async (req, res) => {
  try {
    const { id } = req.params;
    
    const privilege = await PrivilegeService.deletePrivilege(id);
    res.json({
      message: 'Privilege deleted successfully',
      privilege
    });
  } catch (error) {
    console.error('Error deleting privilege:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ error: 'Privilege not found' });
    }
    res.status(500).json({ error: 'Failed to delete privilege' });
  }
});

// GET /api/privileges/user/:userId - Get user's privileges (requires privilege.read)
router.get('/user/:userId', authenticateToken, requirePrivilege('privilege', 'read'), async (req, res) => {
  try {
    const { userId } = req.params;
    
    const userPrivileges = await PrivilegeService.getUserPrivileges(userId);
    res.json({
      message: 'User privileges retrieved successfully',
      privileges: userPrivileges.map(up => ({
        id: up.privilege.id,
        name: up.privilege.name,
        description: up.privilege.description,
        resource: up.privilege.resource,
        action: up.privilege.action,
        grantedAt: up.grantedAt,
        expiresAt: up.expiresAt,
        isActive: up.isActive
      }))
    });
  } catch (error) {
    console.error('Error fetching user privileges:', error);
    res.status(500).json({ error: 'Failed to fetch user privileges' });
  }
});

// POST /api/privileges/grant - Grant privilege to user (requires privilege.grant)
router.post('/grant', authenticateToken, grantPrivilege, async (req, res) => {
  try {
    const { error, value } = grantPrivilegeSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const userPrivilege = await PrivilegeService.grantPrivilegeToUser(
      value.userId, 
      value.privilegeId, 
      req.userId,  // granted by current user
      value.expiresAt
    );
    
    res.status(201).json({
      message: 'Privilege granted successfully',
      userPrivilege
    });
  } catch (error) {
    console.error('Error granting privilege:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'User already has this privilege' });
    }
    res.status(500).json({ error: 'Failed to grant privilege' });
  }
});

// POST /api/privileges/revoke - Revoke privilege from user (requires privilege.revoke)
router.post('/revoke', authenticateToken, revokePrivilege, async (req, res) => {
  try {
    const { error, value } = revokePrivilegeSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.details.map(d => d.message) 
      });
    }

    const result = await PrivilegeService.revokePrivilegeFromUser(
      value.userId, 
      value.privilegeId
    );
    
    res.json({
      message: 'Privilege revoked successfully',
      revokedCount: result.count
    });
  } catch (error) {
    console.error('Error revoking privilege:', error);
    res.status(500).json({ error: 'Failed to revoke privilege' });
  }
});

// GET /api/privileges/:id/users - Get users with specific privilege (requires privilege.read)
router.get('/:id/users', authenticateToken, requirePrivilege('privilege', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    
    const users = await PrivilegeService.getUsersWithPrivilege(id);
    res.json({
      message: 'Users with privilege retrieved successfully',
      users: users.map(up => ({
        id: up.user.id,
        username: up.user.username,
        email: up.user.email,
        grantedAt: up.grantedAt,
        expiresAt: up.expiresAt,
        isActive: up.isActive
      }))
    });
  } catch (error) {
    console.error('Error fetching users with privilege:', error);
    res.status(500).json({ error: 'Failed to fetch users with privilege' });
  }
});

// POST /api/privileges/initialize - Initialize default privileges (requires privilege.create)
router.post('/initialize', authenticateToken, requirePrivilege('privilege', 'create'), async (req, res) => {
  try {
    const privileges = await PrivilegeService.initializeDefaultPrivileges();
    res.json({
      message: 'Default privileges initialized successfully',
      privileges,
      count: privileges.length
    });
  } catch (error) {
    console.error('Error initializing privileges:', error);
    res.status(500).json({ error: 'Failed to initialize privileges' });
  }
});

module.exports = router;
