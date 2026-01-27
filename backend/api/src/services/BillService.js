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
    const { user_id, limit = 50, offset = 0 } = filters;

    if (!user_id) {
      throw new Error('User ID is required');
    }

    const where = {
      userId: parseInt(user_id)
    };

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
            item: true
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
  async getBillById(id, userId) {
    return await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        userId: parseInt(userId)
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
            item: true
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
    const { title, description, amount, user_id } = billData;

    if (!user_id) {
      throw new Error('User ID is required');
    }

    const user = await prisma.user.findUnique({
      where: { id: parseInt(user_id) }
    });

    if (!user) {
      throw new Error('User not found');
    }

    return await prisma.bill.create({
      data: {
        title,
        description,
        amount,
        userId: parseInt(user_id)
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
            item: true
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
  async updateBill(id, userId, updateData) {
    const existingBill = await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        userId: parseInt(userId)
      }
    });

    if (!existingBill) {
      throw new Error('Bill not found');
    }

    const updateFields = {};
    if (updateData.title !== undefined) updateFields.title = updateData.title;
    if (updateData.description !== undefined) updateFields.description = updateData.description;
    if (updateData.amount !== undefined) updateFields.amount = updateData.amount;

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
            item: true
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
  async deleteBill(id, userId) {
    const existingBill = await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        userId: parseInt(userId)
      },
      include: {
        billItems: {
          include: {
            item: true
          }
        }
      }
    });

    if (!existingBill) {
      throw new Error('Bill not found');
    }

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
  async getBillStats(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const where = {
      userId: parseInt(userId)
    };

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
  async getBillsByUserId(userId, options = {}) {
    const { limit = 50, offset = 0 } = options;

    const where = {
      userId: parseInt(userId)
    };

    return await prisma.bill.findMany({
      where,
      include: {
        billItems: {
          include: {
            item: true
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
