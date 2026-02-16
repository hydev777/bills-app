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
    const { branch_id, user_id, status, client_id, limit = 50, offset = 0 } = filters;

    if (!branch_id) {
      throw new Error('Branch ID is required');
    }

    const take = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
    const skip = Math.max(0, parseInt(offset, 10) || 0);

    const where = { branchId: parseInt(branch_id) };
    if (user_id) where.userId = parseInt(user_id);
    if (status) where.status = status;
    const cid = client_id != null && client_id !== '' ? parseInt(client_id, 10) : null;
    if (cid != null && !Number.isNaN(cid) && cid > 0) where.clientId = cid;

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
        client: {
          select: {
            id: true,
            name: true,
            identifier: true,
            taxId: true,
            email: true,
            phone: true,
            address: true
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
      take,
      skip
    });

    const total = await prisma.bill.count({ where });

    return {
      bills,
      total,
      limit: take,
      offset: skip
    };
  }

  /**
   * Get a specific bill by ID
   * @param {number} id - Bill ID
   * @param {number} userId - User ID (for security)
   * @returns {Promise<Object|null>} Bill with related data or null if not found
   */
  async getBillById(id, branchId) {
    return await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        branchId: parseInt(branchId)
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        client: {
          select: {
            id: true,
            name: true,
            identifier: true,
            taxId: true,
            email: true,
            phone: true,
            address: true
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
   * @param {number} branchId - Branch ID
   * @returns {Promise<Object|null>} Bill with related data or null if not found
   */
  async getBillByPublicId(publicId, branchId) {
    return await prisma.bill.findFirst({
      where: {
        publicId,
        branchId: parseInt(branchId)
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        client: {
          select: {
            id: true,
            name: true,
            identifier: true,
            taxId: true,
            email: true,
            phone: true,
            address: true
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
    const { title, description, amount, status, client_id, user_id, branch_id } = billData;

    if (!user_id || !branch_id) {
      throw new Error('User ID and Branch ID are required');
    }

    const user = await prisma.user.findUnique({
      where: { id: parseInt(user_id) }
    });
    if (!user) throw new Error('User not found');

    const branch = await prisma.branch.findUnique({
      where: { id: parseInt(branch_id) }
    });
    if (!branch) throw new Error('Branch not found');

    const clientIdValue =
      client_id != null && client_id !== '' && Number.isInteger(Number(client_id)) && Number(client_id) > 0
        ? parseInt(client_id, 10)
        : null;
    if (clientIdValue != null) {
      const client = await prisma.client.findUnique({
        where: { id: clientIdValue }
      });
      if (!client) throw new Error('Client not found');
    }

    return await prisma.bill.create({
      data: {
        title,
        description,
        subtotal: 0,
        taxAmount: 0,
        amount: amount ?? 0,
        status: status || 'draft',
        clientId: clientIdValue,
        userId: parseInt(user_id),
        branchId: parseInt(branch_id)
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true
          }
        },
        client: {
          select: {
            id: true,
            name: true,
            identifier: true,
            taxId: true,
            email: true,
            phone: true,
            address: true
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
  async updateBill(id, branchId, updateData) {
    const existingBill = await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        branchId: parseInt(branchId)
      }
    });
    if (!existingBill) throw new Error('Bill not found');

    let updateClientId = undefined;
    if (updateData.client_id !== undefined) {
      const cid =
        updateData.client_id != null && updateData.client_id !== '' &&
        Number.isInteger(Number(updateData.client_id)) && Number(updateData.client_id) > 0
          ? parseInt(updateData.client_id, 10)
          : null;
      if (cid != null) {
        const client = await prisma.client.findUnique({
          where: { id: cid }
        });
        if (!client) throw new Error('Client not found');
      }
      updateClientId = cid;
    }

    const updateFields = {};
    if (updateData.title !== undefined) updateFields.title = updateData.title;
    if (updateData.description !== undefined) updateFields.description = updateData.description;
    if (updateData.status !== undefined) updateFields.status = updateData.status;
    if (updateData.client_id !== undefined) updateFields.clientId = updateClientId;
    // amount, subtotal, taxAmount are derived from line items (recalculated when bill items change)

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
        client: {
          select: {
            id: true,
            name: true,
            identifier: true,
            taxId: true,
            email: true,
            phone: true,
            address: true
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
   * Recalculate bill subtotal, tax_amount and amount from line items (quantity * unitPrice per line; tax from item itbisRate).
   * Call after add/update/remove bill items so total stays in sync with lines.
   * @param {number} billId - Bill ID
   * @returns {Promise<void>}
   */
  async recalculateBillTotals(billId) {
    const billItems = await prisma.billItem.findMany({
      where: { billId: parseInt(billId) },
      include: {
        item: {
          include: {
            itbisRate: { select: { percentage: true } }
          }
        }
      }
    });

    let subtotal = 0;
    let taxAmount = 0;
    for (const row of billItems) {
      const qty = Number(row.quantity);
      const unitPrice = parseFloat(row.unitPrice);
      const lineSubtotal = qty * unitPrice;
      const pct = row.item?.itbisRate ? parseFloat(row.item.itbisRate.percentage) : 0;
      const lineTax = lineSubtotal * (pct / 100);
      subtotal += lineSubtotal;
      taxAmount += lineTax;
    }
    const amount = subtotal + taxAmount;

    await prisma.bill.update({
      where: { id: parseInt(billId) },
      data: {
        subtotal: Math.round(subtotal * 100) / 100,
        taxAmount: Math.round(taxAmount * 100) / 100,
        amount: Math.round(amount * 100) / 100
      }
    });
  }

  /**
   * Delete a bill
   * @param {number} id - Bill ID
   * @param {number} userId - User ID (for security)
   * @returns {Promise<Object>} Deleted bill info
   */
  async deleteBill(id, branchId) {
    const existingBill = await prisma.bill.findFirst({
      where: {
        id: parseInt(id),
        branchId: parseInt(branchId)
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
  async getBillStats(branchId) {
    if (!branchId) throw new Error('Branch ID is required');
    const where = { branchId: parseInt(branchId) };

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
  async getBillsByUserId(userId, branchId, options = {}) {
    const { limit = 50, offset = 0 } = options;
    const where = {
      userId: parseInt(userId),
      branchId: parseInt(branchId)
    };

    return await prisma.bill.findMany({
      where,
      include: {
        client: {
          select: {
            id: true,
            name: true,
            identifier: true,
            taxId: true,
            email: true,
            phone: true,
            address: true
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
  }
}

module.exports = new BillService();
