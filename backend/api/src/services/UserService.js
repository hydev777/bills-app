const { prisma } = require('../config/prisma');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { BranchService } = require('./BranchService');

class UserService {
  /**
   * Register a new user
   * @param {Object} userData - User registration data
   * @param {string} userData.username - Username
   * @param {string} userData.email - Email address
   * @param {string} userData.password - Plain text password
   * @returns {Promise<Object>} Created user with token
   */
  async registerUser(userData) {
    const { username, email, password } = userData;

    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    const existing = await prisma.user.findFirst({
      where: { OR: [{ email }, { username }] }
    });
    if (existing) {
      throw new Error('User already exists with this email or username');
    }

    const user = await prisma.user.create({
      data: {
        username,
        email,
        passwordHash,
        role: 'user'
      },
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        createdAt: true
      }
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    return {
      message: 'User created successfully',
      user: { id: user.id, username: user.username, email: user.email, role: user.role },
      token
    };
  }

  /**
   * Login user
   * @param {Object} loginData - Login credentials
   * @param {string} loginData.email - Email address
   * @param {string} loginData.password - Plain text password
   * @returns {Promise<Object>} User info with token
   */
  async loginUser(loginData) {
    const { email, password } = loginData;

    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      throw new Error('Invalid credentials');
    }

    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      throw new Error('Invalid credentials');
    }

    const userBranches = await BranchService.getUserBranches(user.id);

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    return {
      message: 'Login successful',
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      },
      accessibleBranches: userBranches.map(ub => ({
        id: ub.branch.id,
        name: ub.branch.name,
        code: ub.branch.code,
        isPrimary: ub.isPrimary,
        canLogin: ub.canLogin
      })),
      token
    };
  }

  /**
   * Login user to specific branch
   * @param {Object} loginData - Login credentials with branch
   * @param {string} loginData.email - Email address
   * @param {string} loginData.password - Plain text password
   * @param {number} loginData.branchId - Branch ID to login to
   * @returns {Promise<Object>} User info with token and branch info
   */
  async loginUserToBranch(loginData) {
    const { email, password, branchId } = loginData;

    const user = await prisma.user.findUnique({
      where: { email }
    });
    if (!user) throw new Error('Invalid credentials');

    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      throw new Error('Invalid credentials');
    }

    const branch = await BranchService.getBranchById(branchId);
    if (!branch) {
      throw new Error('Branch not found');
    }

    if (!branch.isActive) {
      throw new Error('Branch is not active');
    }

    const canAccess = await BranchService.canUserLoginToBranch(user.id, branchId);
    if (!canAccess) throw new Error('You do not have permission to access this branch');

    const token = jwt.sign(
      { userId: user.id, email: user.email, branchId: branch.id },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    return {
      message: 'Login successful',
      user: {
        id: user.id,
        username: user.username,
        email: user.email
      },
      branch: {
        id: branch.id,
        name: branch.name,
        code: branch.code,
        address: branch.address,
        phone: branch.phone,
        email: branch.email
      },
      token
    };
  }

  /**
   * Get user profile by token
   * @param {string} token - JWT token
   * @returns {Promise<Object>} User profile
   */
  async getUserProfile(token) {
    if (!token) {
      throw new Error('No token provided');
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    } catch (error) {
      if (error.name === 'JsonWebTokenError') {
        throw new Error('Invalid token');
      }
      throw error;
    }
    
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        username: true,
        email: true,
        createdAt: true,
        _count: {
          bills: true
        }
      }
    });

    if (!user) {
      throw new Error('User not found');
    }

    return {
      ...user,
      total_bills: user._count.bills
    };
  }

  /**
   * Get user by ID
   * @param {number} id - User ID
   * @returns {Promise<Object|null>} User or null if not found
   */
  async getUserById(id) {
    return await prisma.user.findUnique({
      where: { id: parseInt(id) },
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        createdAt: true,
        _count: { bills: true }
      }
    });
  }

  /**
   * Create user (global; no organization).
   * @param {Object} userData - username, email, password
   * @param {number} grantedBy - User ID of creator (optional)
   */
  async createUser(userData, grantedBy) {
    const { username, email, password } = userData;

    const existing = await prisma.user.findFirst({
      where: { OR: [{ email }, { username }] }
    });
    if (existing) {
      throw new Error('User already exists with this email or username');
    }

    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    const user = await prisma.user.create({
      data: {
        username,
        email,
        passwordHash,
        role: 'user'
      },
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        createdAt: true
      }
    });

    return user;
  }

  /**
   * Get all users with pagination
   * @param {Object} options - Query options
   * @param {number} options.limit - Limit results (default: 50)
   * @param {number} options.offset - Offset for pagination (default: 0)
   * @returns {Promise<Object>} Users with pagination info
   */
  async getAllUsers(options = {}) {
    const { limit = 50, offset = 0 } = options;

    const users = await prisma.user.findMany({
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        createdAt: true,
        _count: { bills: true }
      },
      orderBy: { createdAt: 'desc' },
      take: Math.min(100, Math.max(1, parseInt(limit, 10) || 50)),
      skip: Math.max(0, parseInt(offset, 10) || 0)
    });

    const total = await prisma.user.count();

    return {
      users: users.map(u => ({ ...u, total_bills: u._count.bills })),
      total,
      limit: Math.min(100, Math.max(1, parseInt(limit, 10) || 50)),
      offset: Math.max(0, parseInt(offset, 10) || 0)
    };
  }

  /**
   * Get user bills
   * @param {number} userId - User ID
   * @param {Object} options - Query options
   * @returns {Promise<Object>} User bills with pagination
   */
  async getUserBills(userId, branchId, options = {}) {
    const { limit = 50, offset = 0 } = options;

    const user = await prisma.user.findUnique({
      where: { id: parseInt(userId) },
      select: { id: true, username: true, email: true }
    });

    if (!user) {
      throw new Error('User not found');
    }

    const where = { userId: parseInt(userId), branchId: parseInt(branchId) };

    const bills = await prisma.bill.findMany({
      where,
      include: {
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          }
        },
        _count: {
          billItems: true
        }
      },
      orderBy: {
        createdAt: 'desc'
      },
      take: parseInt(limit),
      skip: parseInt(offset)
    });

    const total = await prisma.bill.count({ where });

    return {
      user,
      bills,
      total,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };
  }

  /**
   * Get user statistics (branch-scoped: bills in the given branch only)
   * @param {number} userId - User ID
   * @param {number} branchId - Branch ID
   * @returns {Promise<Object>} User statistics for that branch
   */
  async getUserStats(userId, branchId) {
    const user = await prisma.user.findUnique({
      where: { id: parseInt(userId) },
      select: { id: true, username: true, email: true }
    });

    if (!user) {
      throw new Error('User not found');
    }

    const where = { userId: parseInt(userId), branchId: parseInt(branchId) };

    const totalBills = await prisma.bill.count({ where });

    const amountAggregation = await prisma.bill.aggregate({
      where,
      _sum: { amount: true }
    });
    const totalAmount = parseFloat(amountAggregation._sum.amount || 0);

    const totalBillItems = await prisma.billItem.count({
      where: {
        bill: { userId: parseInt(userId), branchId: parseInt(branchId) }
      }
    });

    return {
      user,
      stats: {
        total_bills: totalBills,
        total_amount: totalAmount,
        total_bill_items: totalBillItems
      }
    };
  }

  /**
   * Update user profile
   * @param {number} userId - User ID
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated user
   */
  async updateUserProfile(userId, updateData) {
    const { username, email } = updateData;

    // Check if user exists
    const existingUser = await prisma.user.findUnique({
      where: { id: parseInt(userId) }
    });

    if (!existingUser) {
      throw new Error('User not found');
    }

    if (username && username !== existingUser.username) {
      const dup = await prisma.user.findUnique({
        where: { username }
      });
      if (dup) throw new Error('Username already exists');
    }
    if (email && email !== existingUser.email) {
      const dup = await prisma.user.findUnique({
        where: { email }
      });
      if (dup) throw new Error('Email already exists');
    }

    const updateFields = {};
    if (username !== undefined) updateFields.username = username;
    if (email !== undefined) updateFields.email = email;

    return await prisma.user.update({
      where: { id: parseInt(userId) },
      data: updateFields,
      select: {
        id: true,
        username: true,
        email: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }

  /**
   * Change user password
   * @param {number} userId - User ID
   * @param {Object} passwordData - Password change data
   * @param {string} passwordData.currentPassword - Current password
   * @param {string} passwordData.newPassword - New password
   * @returns {Promise<Object>} Success message
   */
  async changeUserPassword(userId, passwordData) {
    const { currentPassword, newPassword } = passwordData;

    // Get user with password hash
    const user = await prisma.user.findUnique({
      where: { id: parseInt(userId) }
    });

    if (!user) {
      throw new Error('User not found');
    }

    // Verify current password
    const isValidPassword = await bcrypt.compare(currentPassword, user.passwordHash);
    
    if (!isValidPassword) {
      throw new Error('Current password is incorrect');
    }

    // Hash new password
    const saltRounds = 12;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await prisma.user.update({
      where: { id: parseInt(userId) },
      data: { passwordHash: newPasswordHash }
    });

    return { message: 'Password changed successfully' };
  }

  /**
   * Delete user account
   * @param {number} userId - User ID
   * @returns {Promise<Object>} Deletion result
   */
  async deleteUser(userId) {
    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { id: parseInt(userId) },
      include: {
        _count: {
          bills: true
        }
      }
    });

    if (!user) {
      throw new Error('User not found');
    }

    // Delete user (bills will be deleted due to cascade)
    await prisma.user.delete({
      where: { id: parseInt(userId) }
    });

    return {
      message: 'User deleted successfully',
      deletedBillsCount: user._count.bills
    };
  }

  /**
   * Verify JWT token
   * @param {string} token - JWT token
   * @returns {Promise<Object>} Decoded token data
   */
  async verifyToken(token) {
    if (!token) {
      throw new Error('No token provided');
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
      
      // Verify user still exists
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: { id: true, email: true }
      });

      if (!user) {
        throw new Error('User not found');
      }

      return decoded;
    } catch (error) {
      if (error.name === 'JsonWebTokenError') {
        throw new Error('Invalid token');
      }
      throw error;
    }
  }
}

module.exports = new UserService();
