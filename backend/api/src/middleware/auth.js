const jwt = require('jsonwebtoken');
const { prisma } = require('../config/prisma');
const { BranchService, PrivilegeService } = require('../services');

/**
 * JWT Authentication Middleware
 * Verifies JWT token and adds user info to request object
 */
const authenticateToken = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.startsWith('Bearer ') 
      ? authHeader.slice(7) 
      : null;

    if (!token) {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'No token provided' 
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    // Check if user still exists
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        createdAt: true
      }
    });

    if (!user) {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'User not found' 
      });
    }

    // Add user info to request object
    req.user = user;
    req.userId = user.id;
    
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'Invalid token' 
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'Token expired' 
      });
    }
    
    return res.status(500).json({ 
      error: 'Authentication error', 
      message: 'Failed to authenticate token' 
    });
  }
};

/**
 * Optional Authentication Middleware
 * Adds user info if token is provided, but doesn't require it
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.startsWith('Bearer ') 
      ? authHeader.slice(7) 
      : null;

    if (!token) {
      req.user = null;
      req.userId = null;
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        createdAt: true
      }
    });

    req.user = user || null;
    req.userId = user ? user.id : null;
    
    next();
  } catch (error) {
    // If token is invalid, continue without user info
    req.user = null;
    req.userId = null;
    next();
  }
};

/**
 * Admin/Owner Authorization Middleware
 * Checks if user owns the resource or is admin
 */
const authorizeOwnerOrAdmin = (resourceUserIdField = 'user_id') => {
  return (req, res, next) => {
    const resourceUserId = req.params[resourceUserIdField] || req.body[resourceUserIdField];
    
    // If no specific user is being accessed, allow (for general endpoints)
    if (!resourceUserId) {
      return next();
    }
    
    // Check if user is accessing their own resources
    if (parseInt(resourceUserId) === req.userId) {
      return next();
    }
    
    // TODO: Add admin role check here if needed
    // if (req.user.role === 'admin') {
    //   return next();
    // }
    
    return res.status(403).json({ 
      error: 'Forbidden', 
      message: 'You can only access your own resources' 
    });
  };
};

/**
 * Branch Authentication Middleware
 * Verifies JWT token and checks if user can access the specified branch
 * Expects branch_id in request body or query params
 */
const authenticateBranchAccess = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.startsWith('Bearer ') 
      ? authHeader.slice(7) 
      : null;

    if (!token) {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'No token provided' 
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    // Get branch_id from body or query params
    const branchId = req.body.branch_id || req.query.branch_id;
    
    if (!branchId) {
      return res.status(400).json({ 
        error: 'Bad request', 
        message: 'Branch ID is required' 
      });
    }
    
    // Check if user still exists
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        username: true,
        email: true,
        createdAt: true
      }
    });

    if (!user) {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'User not found' 
      });
    }

    // Check if user can access the specified branch
    const canAccess = await BranchService.canUserLoginToBranch(user.id, branchId);
    
    if (!canAccess) {
      return res.status(403).json({ 
        error: 'Access denied', 
        message: 'You do not have permission to access this branch' 
      });
    }

    // Get branch information
    const branch = await BranchService.getBranchById(branchId);
    
    if (!branch) {
      return res.status(404).json({ 
        error: 'Not found', 
        message: 'Branch not found' 
      });
    }

    // Add user and branch info to request object
    req.user = user;
    req.userId = user.id;
    req.branch = branch;
    req.branchId = branch.id;
    
    next();
  } catch (error) {
    console.error('Branch auth middleware error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'Invalid token' 
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        error: 'Access denied', 
        message: 'Token expired' 
      });
    }
    
    return res.status(500).json({ 
      error: 'Authentication error', 
      message: 'Failed to authenticate token' 
    });
  }
};

/**
 * Validate User ID Parameter Middleware
 * Ensures the user_id parameter matches the authenticated user
 */
const validateUserAccess = (req, res, next) => {
  const requestedUserId = parseInt(req.params.id || req.params.user_id);
  
  if (requestedUserId && requestedUserId !== req.userId) {
    return res.status(403).json({ 
      error: 'Forbidden', 
      message: 'You can only access your own resources' 
    });
  }
  
  next();
};

/**
 * Require specific privilege middleware
 * Checks if user has the required privilege
 * @param {string} resource - Resource name (e.g., 'branch', 'user')
 * @param {string} action - Action name (e.g., 'create', 'read', 'update', 'delete')
 * @returns {Function} Middleware function
 */
const requirePrivilege = (resource, action) => {
  return async (req, res, next) => {
    try {
      if (!req.userId) {
        return res.status(401).json({ 
          error: 'Unauthorized', 
          message: 'Authentication required' 
        });
      }

      const hasPrivilege = await PrivilegeService.userHasPrivilege(req.userId, resource, action);
      
      if (!hasPrivilege) {
        return res.status(403).json({ 
          error: 'Forbidden', 
          message: `Insufficient privileges. Required: ${resource}.${action}` 
        });
      }

      next();
    } catch (error) {
      console.error('Privilege middleware error:', error);
      res.status(500).json({ 
        error: 'Authorization error', 
        message: 'Failed to check privileges' 
      });
    }
  };
};

/**
 * Require any of the specified privileges middleware
 * Checks if user has any of the required privileges
 * @param {Array} privileges - Array of privilege objects with resource and action
 * @returns {Function} Middleware function
 */
const requireAnyPrivilege = (privileges) => {
  return async (req, res, next) => {
    try {
      if (!req.userId) {
        return res.status(401).json({ 
          error: 'Unauthorized', 
          message: 'Authentication required' 
        });
      }

      const hasAnyPrivilege = await PrivilegeService.userHasAnyPrivilege(req.userId, privileges);
      
      if (!hasAnyPrivilege) {
        const requiredPrivileges = privileges.map(p => `${p.resource}.${p.action}`).join(', ');
        return res.status(403).json({ 
          error: 'Forbidden', 
          message: `Insufficient privileges. Required any of: ${requiredPrivileges}` 
        });
      }

      next();
    } catch (error) {
      console.error('Privilege middleware error:', error);
      res.status(500).json({ 
        error: 'Authorization error', 
        message: 'Failed to check privileges' 
      });
    }
  };
};

/**
 * Require all specified privileges middleware
 * Checks if user has all of the required privileges
 * @param {Array} privileges - Array of privilege objects with resource and action
 * @returns {Function} Middleware function
 */
const requireAllPrivileges = (privileges) => {
  return async (req, res, next) => {
    try {
      if (!req.userId) {
        return res.status(401).json({ 
          error: 'Unauthorized', 
          message: 'Authentication required' 
        });
      }

      // Check each privilege individually
      for (const privilege of privileges) {
        const hasPrivilege = await PrivilegeService.userHasPrivilege(
          req.userId, 
          privilege.resource, 
          privilege.action
        );
        
        if (!hasPrivilege) {
          return res.status(403).json({ 
            error: 'Forbidden', 
            message: `Insufficient privileges. Required: ${privilege.resource}.${privilege.action}` 
          });
        }
      }

      next();
    } catch (error) {
      console.error('Privilege middleware error:', error);
      res.status(500).json({ 
        error: 'Authorization error', 
        message: 'Failed to check privileges' 
      });
    }
  };
};

/**
 * Grant privilege to user middleware
 * Requires privilege.grant privilege
 * @param {number} targetUserId - User ID to grant privilege to
 * @param {number} privilegeId - Privilege ID to grant
 * @returns {Function} Middleware function
 */
const grantPrivilege = async (req, res, next) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Authentication required' 
      });
    }

    const canGrant = await PrivilegeService.userHasPrivilege(req.userId, 'privilege', 'grant');
    
    if (!canGrant) {
      return res.status(403).json({ 
        error: 'Forbidden', 
        message: 'Insufficient privileges to grant privileges' 
      });
    }

    next();
  } catch (error) {
    console.error('Grant privilege middleware error:', error);
    res.status(500).json({ 
      error: 'Authorization error', 
      message: 'Failed to check grant privileges' 
    });
  }
};

/**
 * Revoke privilege from user middleware
 * Requires privilege.revoke privilege
 * @returns {Function} Middleware function
 */
const revokePrivilege = async (req, res, next) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Authentication required' 
      });
    }

    const canRevoke = await PrivilegeService.userHasPrivilege(req.userId, 'privilege', 'revoke');
    
    if (!canRevoke) {
      return res.status(403).json({ 
        error: 'Forbidden', 
        message: 'Insufficient privileges to revoke privileges' 
      });
    }

    next();
  } catch (error) {
    console.error('Revoke privilege middleware error:', error);
    res.status(500).json({ 
      error: 'Authorization error', 
      message: 'Failed to check revoke privileges' 
    });
  }
};

module.exports = {
  authenticateToken,
  optionalAuth,
  authorizeOwnerOrAdmin,
  authenticateBranchAccess,
  validateUserAccess,
  requirePrivilege,
  requireAnyPrivilege,
  requireAllPrivileges,
  grantPrivilege,
  revokePrivilege
};
