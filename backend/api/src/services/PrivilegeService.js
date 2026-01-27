const { prisma } = require('../config/prisma');

class PrivilegeService {
  /**
   * Get all privileges
   * @returns {Promise<Array>} List of all privileges
   */
  async getAllPrivileges() {
    return await prisma.privilege.findMany({
      where: { isActive: true },
      orderBy: [
        { resource: 'asc' },
        { action: 'asc' }
      ],
      select: {
        id: true,
        name: true,
        description: true,
        resource: true,
        action: true,
        isActive: true,
        createdAt: true,
        _count: {
          userPrivileges: true
        }
      }
    });
  }

  /**
   * Get privilege by ID
   * @param {number} privilegeId - Privilege ID
   * @returns {Promise<Object|null>} Privilege or null if not found
   */
  async getPrivilegeById(privilegeId) {
    return await prisma.privilege.findUnique({
      where: { id: parseInt(privilegeId) },
      select: {
        id: true,
        name: true,
        description: true,
        resource: true,
        action: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
        userPrivileges: {
          where: { isActive: true },
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
          userPrivileges: true
        }
      }
    });
  }

  /**
   * Get privilege by name
   * @param {string} name - Privilege name
   * @returns {Promise<Object|null>} Privilege or null if not found
   */
  async getPrivilegeByName(name) {
    return await prisma.privilege.findUnique({
      where: { name },
      select: {
        id: true,
        name: true,
        description: true,
        resource: true,
        action: true,
        isActive: true,
        createdAt: true
      }
    });
  }

  /**
   * Get privilege by resource and action
   * @param {string} resource - Resource name (e.g., 'branch', 'user')
   * @param {string} action - Action name (e.g., 'create', 'read', 'update', 'delete')
   * @returns {Promise<Object|null>} Privilege or null if not found
   */
  async getPrivilegeByResourceAction(resource, action) {
    return await prisma.privilege.findUnique({
      where: {
        resource_action: {
          resource,
          action
        }
      },
      select: {
        id: true,
        name: true,
        description: true,
        resource: true,
        action: true,
        isActive: true,
        createdAt: true
      }
    });
  }

  /**
   * Create a new privilege
   * @param {Object} privilegeData - Privilege data
   * @param {string} privilegeData.name - Privilege name
   * @param {string} privilegeData.description - Privilege description
   * @param {string} privilegeData.resource - Resource name
   * @param {string} privilegeData.action - Action name
   * @returns {Promise<Object>} Created privilege
   */
  async createPrivilege(privilegeData) {
    const { name, description, resource, action, isActive = true } = privilegeData;

    return await prisma.privilege.create({
      data: {
        name,
        description,
        resource,
        action,
        isActive
      },
      select: {
        id: true,
        name: true,
        description: true,
        resource: true,
        action: true,
        isActive: true,
        createdAt: true
      }
    });
  }

  /**
   * Update privilege
   * @param {number} privilegeId - Privilege ID
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated privilege
   */
  async updatePrivilege(privilegeId, updateData) {
    const { name, description, resource, action, isActive } = updateData;

    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (description !== undefined) updateFields.description = description;
    if (resource !== undefined) updateFields.resource = resource;
    if (action !== undefined) updateFields.action = action;
    if (isActive !== undefined) updateFields.isActive = isActive;

    return await prisma.privilege.update({
      where: { id: parseInt(privilegeId) },
      data: updateFields,
      select: {
        id: true,
        name: true,
        description: true,
        resource: true,
        action: true,
        isActive: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }

  /**
   * Delete privilege (soft delete by setting isActive to false)
   * @param {number} privilegeId - Privilege ID
   * @returns {Promise<Object>} Updated privilege
   */
  async deletePrivilege(privilegeId) {
    return await prisma.privilege.update({
      where: { id: parseInt(privilegeId) },
      data: { isActive: false },
      select: {
        id: true,
        name: true,
        description: true,
        resource: true,
        action: true,
        isActive: true,
        updatedAt: true
      }
    });
  }

  /**
   * Get user's privileges
   * @param {number} userId - User ID
   * @returns {Promise<Array>} List of user's privileges
   */
  async getUserPrivileges(userId) {
    return await prisma.userPrivilege.findMany({
      where: {
        userId: parseInt(userId),
        isActive: true,
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: new Date() } }
        ]
      },
      include: {
        privilege: {
          select: {
            id: true,
            name: true,
            description: true,
            resource: true,
            action: true,
            isActive: true
          }
        }
      },
      orderBy: [
        { privilege: { resource: 'asc' } },
        { privilege: { action: 'asc' } }
      ]
    });
  }

  /**
   * Check if user has a specific privilege
   * @param {number} userId - User ID
   * @param {string} resource - Resource name
   * @param {string} action - Action name
   * @returns {Promise<boolean>} True if user has the privilege
   */
  async userHasPrivilege(userId, resource, action) {
    const userPrivilege = await prisma.userPrivilege.findFirst({
      where: {
        userId: parseInt(userId),
        isActive: true,
        privilege: {
          resource,
          action,
          isActive: true
        },
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: new Date() } }
        ]
      }
    });

    return !!userPrivilege;
  }

  /**
   * Check if user has any of the specified privileges
   * @param {number} userId - User ID
   * @param {Array} privileges - Array of privilege objects with resource and action
   * @returns {Promise<boolean>} True if user has any of the privileges
   */
  async userHasAnyPrivilege(userId, privileges) {
    const privilegeConditions = privileges.map(p => ({
      privilege: {
        resource: p.resource,
        action: p.action,
        isActive: true
      }
    }));

    const userPrivilege = await prisma.userPrivilege.findFirst({
      where: {
        userId: parseInt(userId),
        isActive: true,
        OR: privilegeConditions,
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: new Date() } }
        ]
      }
    });

    return !!userPrivilege;
  }

  /**
   * Grant privilege to user
   * @param {number} userId - User ID
   * @param {number} privilegeId - Privilege ID
   * @param {number} grantedBy - User ID who is granting the privilege
   * @param {Date} expiresAt - Optional expiration date
   * @returns {Promise<Object>} Created user privilege
   */
  async grantPrivilegeToUser(userId, privilegeId, grantedBy, expiresAt = null) {
    return await prisma.userPrivilege.create({
      data: {
        userId: parseInt(userId),
        privilegeId: parseInt(privilegeId),
        grantedBy: parseInt(grantedBy),
        expiresAt
      },
      include: {
        privilege: {
          select: {
            id: true,
            name: true,
            description: true,
            resource: true,
            action: true
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
   * Revoke privilege from user
   * @param {number} userId - User ID
   * @param {number} privilegeId - Privilege ID
   * @returns {Promise<Object>} Updated user privilege
   */
  async revokePrivilegeFromUser(userId, privilegeId) {
    return await prisma.userPrivilege.updateMany({
      where: {
        userId: parseInt(userId),
        privilegeId: parseInt(privilegeId)
      },
      data: { isActive: false }
    });
  }

  /**
   * Get users with a specific privilege
   * @param {number} privilegeId - Privilege ID
   * @returns {Promise<Array>} List of users with the privilege
   */
  async getUsersWithPrivilege(privilegeId) {
    return await prisma.userPrivilege.findMany({
      where: {
        privilegeId: parseInt(privilegeId),
        isActive: true,
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: new Date() } }
        ]
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
            createdAt: true
          }
        }
      },
      orderBy: {
        user: {
          username: 'asc'
        }
      }
    });
  }

  /**
   * Initialize default privileges
   * Creates common privileges for the system
   * @returns {Promise<Array>} Created privileges
   */
  async initializeDefaultPrivileges() {
    const defaultPrivileges = [
      // Branch privileges
      { name: 'branch.create', description: 'Create new branches', resource: 'branch', action: 'create' },
      { name: 'branch.read', description: 'View branch information', resource: 'branch', action: 'read' },
      { name: 'branch.update', description: 'Update branch information', resource: 'branch', action: 'update' },
      { name: 'branch.delete', description: 'Delete branches', resource: 'branch', action: 'delete' },
      
      // User privileges
      { name: 'user.create', description: 'Create new users', resource: 'user', action: 'create' },
      { name: 'user.read', description: 'View user information', resource: 'user', action: 'read' },
      { name: 'user.update', description: 'Update user information', resource: 'user', action: 'update' },
      { name: 'user.delete', description: 'Delete users', resource: 'user', action: 'delete' },
      
      // Bill privileges
      { name: 'bill.create', description: 'Create new bills', resource: 'bill', action: 'create' },
      { name: 'bill.read', description: 'View bill information', resource: 'bill', action: 'read' },
      { name: 'bill.update', description: 'Update bill information', resource: 'bill', action: 'update' },
      { name: 'bill.delete', description: 'Delete bills', resource: 'bill', action: 'delete' },
      
      // Item privileges
      { name: 'item.create', description: 'Create new items', resource: 'item', action: 'create' },
      { name: 'item.read', description: 'View item information', resource: 'item', action: 'read' },
      { name: 'item.update', description: 'Update item information', resource: 'item', action: 'update' },
      { name: 'item.delete', description: 'Delete items', resource: 'item', action: 'delete' },
      
      // Privilege management
      { name: 'privilege.grant', description: 'Grant privileges to users', resource: 'privilege', action: 'grant' },
      { name: 'privilege.revoke', description: 'Revoke privileges from users', resource: 'privilege', action: 'revoke' },
      { name: 'privilege.read', description: 'View privilege information', resource: 'privilege', action: 'read' }
    ];

    const createdPrivileges = [];
    
    for (const privilege of defaultPrivileges) {
      try {
        const existingPrivilege = await this.getPrivilegeByName(privilege.name);
        if (!existingPrivilege) {
          const created = await this.createPrivilege(privilege);
          createdPrivileges.push(created);
        }
      } catch (error) {
        console.error(`Error creating privilege ${privilege.name}:`, error);
      }
    }

    return createdPrivileges;
  }
}

module.exports = new PrivilegeService();
