const { prisma } = require('../config/prisma');

class BillService {
  /**
   * Get all bills with optional filtering
   * @param {Object} filters - Filter options
   * @param {number} filters.user_id - User ID (required)
   * @param {number} filters.limit - Limit results (default: 50)
   * @param {number} filters.offset - Offset for pagination (default: 0)
   * @returns {Promise<Object>} Bills with pagination info
   */
  async getAllBills(filters = {}) {
    const { organization_id, user_id, status, limit = 50, offset = 0 } = filters;

    if (!organization_id) {
      throw new Error('Organization ID is required');
    }

    const where = { organizationId: parseInt(organization_id) };
    if (user_id) where.userId = parseInt(user_id);
    if (status) where.status = status;

    const bills = await prisma.bill.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          }
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
      bills,
      total,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };
  }

  /**
   * Get a specific bill by ID
   * @param {number} id - Bill ID
   * @param {number} userId - User ID (for security)
   * @returns {Promise<Object|null>} Bill with related data or null if not found
   */
  async getBillById(id, organizationId) {
    return await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        organizationId: parseInt(organizationId)
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          },
          orderBy: {
            createdAt: 'asc'
          }
        }
      }
    });
  }

  /**
   * Get a bill by its unique public ID
   * @param {string} publicId - Bill public UUID
   * @param {number} organizationId - Organization ID
   * @returns {Promise<Object|null>} Bill with related data or null if not found
   */
  async getBillByPublicId(publicId, organizationId) {
    return await prisma.bill.findFirst({
      where: {
        publicId,
        organizationId: parseInt(organizationId)
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          },
          orderBy: {
            createdAt: 'asc'
          }
        }
      }
    });
  }

  /**
   * Create a new bill
   * @param {Object} billData - Bill data
   * @returns {Promise<Object>} Created bill
   */
  async createBill(billData) {
    const { title, description, amount, status, user_id, organization_id } = billData;

    if (!user_id || !organization_id) {
      throw new Error('User ID and Organization ID are required');
    }

    const user = await prisma.user.findFirst({
      where: { id: parseInt(user_id), organizationId: parseInt(organization_id) }
    });
    if (!user) throw new Error('User not found');

    return await prisma.bill.create({
      data: {
        title,
        description,
        amount: amount ?? 0,
        status: status || 'draft',
        userId: parseInt(user_id),
        organizationId: parseInt(organization_id)
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          }
        }
      }
    });
  }

  /**
   * Update an existing bill
   * @param {number} id - Bill ID
   * @param {number} userId - User ID (for security)
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated bill
   */
  async updateBill(id, organizationId, updateData) {
    const existingBill = await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        organizationId: parseInt(organizationId)
      }
    });
    if (!existingBill) throw new Error('Bill not found');

    const updateFields = {};
    if (updateData.title !== undefined) updateFields.title = updateData.title;
    if (updateData.description !== undefined) updateFields.description = updateData.description;
    if (updateData.amount !== undefined) updateFields.amount = updateData.amount;
    if (updateData.status !== undefined) updateFields.status = updateData.status;

    return await prisma.bill.update({
      where: { id: parseInt(id) },
      data: updateFields,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          }
        }
      }
    });
  }

  /**
   * Delete a bill
   * @param {number} id - Bill ID
   * @param {number} userId - User ID (for security)
   * @returns {Promise<Object>} Deleted bill info
   */
  async deleteBill(id, organizationId) {
    const existingBill = await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        organizationId: parseInt(organizationId)
      },
      include: {
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          }
        }
      }
    });
    if (!existingBill) throw new Error('Bill not found');

    await prisma.bill.delete({
      where: { id: parseInt(id) }
    });

    return {
      message: 'Bill deleted successfully',
      bill: existingBill
    };
  }

  /**
   * Get bill summary statistics
   * @param {number} userId - User ID (required)
   * @returns {Promise<Object>} Bill statistics
   */
  async getBillStats(organizationId) {
    if (!organizationId) throw new Error('Organization ID is required');
    const where = { organizationId: parseInt(organizationId) };

    const totalBills = await prisma.bill.count({ where });

    const amountAggregation = await prisma.bill.aggregate({
      where,
      _sum: {
        amount: true
      }
    });

    const totalAmount = parseFloat(amountAggregation._sum.amount || 0);

    return {
      total_bills: totalBills,
      total_amount: totalAmount
    };
  }

  /**
   * Get bills by user ID
   * @param {number} userId - User ID
   * @param {Object} options - Query options
   * @returns {Promise<Array>} User's bills
   */
  async getBillsByUserId(userId, organizationId, options = {}) {
    const { limit = 50, offset = 0 } = options;
    const where = {
      userId: parseInt(userId),
      organizationId: parseInt(organizationId)
    };

    return await prisma.bill.findMany({
      where,
      include: {
        billItems: {
          include: {
            item: { include: { itbisRate: true } }
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      },
      take: parseInt(limit),
      skip: parseInt(offset)
    });
  }
}

module.exports = new BillService();
