const { prisma } = require('../config/prisma');

class BranchService {
  /**
   * Get all active branches
   * @returns {Promise<Array>} List of active branches
   */
  async getAllBranches(organizationId) {
    if (!organizationId) throw new Error('Organization ID is required');
    return await prisma.branch.findMany({
      where: { organizationId: parseInt(organizationId), isActive: true },
      orderBy: { name: 'asc' },
      select: {
        id: true,
        name: true,
        code: true,
        address: true,
        phone: true,
        email: true,
        isActive: true,
        createdAt: true,
        _count: {
          userBranches: true
        }
      }
    });
  }

  /**
   * Get branch by ID
   * @param {number} branchId - Branch ID
   * @returns {Promise<Object|null>} Branch or null if not found
   */
  async getBranchById(branchId, organizationId) {
    return await prisma.branch.findFirst({
      where: { id: parseInt(branchId), organizationId: parseInt(organizationId) },
      select: {
        id: true,
        name: true,
        code: true,
        address: true,
        phone: true,
        email: true,
        isActive: true,
        createdAt: true,
        userBranches: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                email: true
              }
            }
          }
        },
        _count: {
          userBranches: true
        }
      }
    });
  }

  /**
   * Get branch by code
   * @param {string} code - Branch code
   * @returns {Promise<Object|null>} Branch or null if not found
   */
  async getBranchByCode(code, organizationId) {
    if (!organizationId) throw new Error('Organization ID is required');
    return await prisma.branch.findFirst({
      where: { code: code.toUpperCase(), organizationId: parseInt(organizationId) },
      select: {
        id: true,
        name: true,
        code: true,
        address: true,
        phone: true,
        email: true,
        isActive: true,
        createdAt: true
      }
    });
  }

  /**
   * Get user's accessible branches
   * @param {number} userId - User ID
   * @returns {Promise<Array>} List of branches user can access
   */
  async getUserBranches(userId) {
    return await prisma.userBranch.findMany({
      where: {
        userId: parseInt(userId),
        canLogin: true
      },
      include: {
        branch: {
          select: {
            id: true,
            name: true,
            code: true,
            address: true,
            phone: true,
            email: true,
            isActive: true
          }
        }
      },
      orderBy: [
        { isPrimary: 'desc' },
        { branch: { name: 'asc' } }
      ]
    });
  }

  /**
   * Check if user can login to a specific branch
   * @param {number} userId - User ID
   * @param {number} branchId - Branch ID
   * @returns {Promise<boolean>} True if user can login to branch
   */
  async canUserLoginToBranch(userId, branchId) {
    const userBranch = await prisma.userBranch.findUnique({
      where: {
        userId_branchId: {
          userId: parseInt(userId),
          branchId: parseInt(branchId)
        }
      },
      select: {
        canLogin: true,
        branch: {
          select: {
            isActive: true
          }
        }
      }
    });

    return userBranch && userBranch.canLogin && userBranch.branch.isActive;
  }

  /**
   * Get user's primary branch
   * @param {number} userId - User ID
   * @returns {Promise<Object|null>} Primary branch or null if not found
   */
  async getUserPrimaryBranch(userId) {
    const userBranch = await prisma.userBranch.findFirst({
      where: {
        userId: parseInt(userId),
        isPrimary: true,
        canLogin: true
      },
      include: {
        branch: {
          select: {
            id: true,
            name: true,
            code: true,
            address: true,
            phone: true,
            email: true,
            isActive: true
          }
        }
      }
    });

    return userBranch ? userBranch.branch : null;
  }

  /**
   * Add user to a branch
   * @param {number} userId - User ID
   * @param {number} branchId - Branch ID
   * @param {Object} options - Additional options
   * @param {boolean} options.isPrimary - Whether this is the user's primary branch
   * @param {boolean} options.canLogin - Whether user can login to this branch
   * @returns {Promise<Object>} Created user-branch relationship
   */
  async addUserToBranch(userId, branchId, options = {}) {
    const { isPrimary = false, canLogin = true } = options;

    // If setting as primary, unset other primary branches for this user
    if (isPrimary) {
      await prisma.userBranch.updateMany({
        where: {
          userId: parseInt(userId),
          isPrimary: true
        },
        data: {
          isPrimary: false
        }
      });
    }

    return await prisma.userBranch.create({
      data: {
        userId: parseInt(userId),
        branchId: parseInt(branchId),
        isPrimary,
        canLogin
      },
      include: {
        branch: {
          select: {
            id: true,
            name: true,
            code: true,
            address: true,
            phone: true,
            email: true,
            isActive: true
          }
        },
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        }
      }
    });
  }

  /**
   * Remove user from a branch
   * @param {number} userId - User ID
   * @param {number} branchId - Branch ID
   * @returns {Promise<Object>} Deletion result
   */
  async removeUserFromBranch(userId, branchId) {
    const deleted = await prisma.userBranch.deleteMany({
      where: {
        userId: parseInt(userId),
        branchId: parseInt(branchId)
      }
    });

    return {
      message: 'User removed from branch successfully',
      deletedCount: deleted.count
    };
  }

  /**
   * Update user's branch permissions
   * @param {number} userId - User ID
   * @param {number} branchId - Branch ID
   * @param {Object} updateData - Update data
   * @param {boolean} updateData.isPrimary - Whether this is the user's primary branch
   * @param {boolean} updateData.canLogin - Whether user can login to this branch
   * @returns {Promise<Object>} Updated user-branch relationship
   */
  async updateUserBranchPermissions(userId, branchId, updateData) {
    const { isPrimary, canLogin } = updateData;

    // If setting as primary, unset other primary branches for this user
    if (isPrimary === true) {
      await prisma.userBranch.updateMany({
        where: {
          userId: parseInt(userId),
          isPrimary: true
        },
        data: {
          isPrimary: false
        }
      });
    }

    const updateFields = {};
    if (isPrimary !== undefined) updateFields.isPrimary = isPrimary;
    if (canLogin !== undefined) updateFields.canLogin = canLogin;

    return await prisma.userBranch.update({
      where: {
        userId_branchId: {
          userId: parseInt(userId),
          branchId: parseInt(branchId)
        }
      },
      data: updateFields,
      include: {
        branch: {
          select: {
            id: true,
            name: true,
            code: true,
            address: true,
            phone: true,
            email: true,
            isActive: true
          }
        },
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        }
      }
    });
  }

  /**
   * Create a new branch
   * @param {Object} branchData - Branch data
   * @returns {Promise<Object>} Created branch
   */
  async createBranch(branchData) {
    const { organization_id, name, code, address, phone, email, isActive = true } = branchData;

    if (!organization_id) throw new Error('Organization ID is required');

    return await prisma.branch.create({
      data: {
        organizationId: parseInt(organization_id),
        name,
        code: code.toUpperCase(),
        address,
        phone,
        email,
        isActive
      },
      select: {
        id: true,
        name: true,
        code: true,
        address: true,
        phone: true,
        email: true,
        isActive: true,
        createdAt: true
      }
    });
  }

  /**
   * Update branch information
   * @param {number} branchId - Branch ID
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated branch
   */
  async updateBranch(branchId, organizationId, updateData) {
    const { name, code, address, phone, email, isActive } = updateData;

    const existing = await prisma.branch.findFirst({
      where: { id: parseInt(branchId), organizationId: parseInt(organizationId) }
    });
    if (!existing) throw new Error('Branch not found');

    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (code !== undefined) updateFields.code = code.toUpperCase();
    if (address !== undefined) updateFields.address = address;
    if (phone !== undefined) updateFields.phone = phone;
    if (email !== undefined) updateFields.email = email;
    if (isActive !== undefined) updateFields.isActive = isActive;

    return await prisma.branch.update({
      where: { id: parseInt(branchId) },
      data: updateFields,
      select: {
        id: true,
        name: true,
        code: true,
        address: true,
        phone: true,
        email: true,
        isActive: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }
}

module.exports = new BranchService();

