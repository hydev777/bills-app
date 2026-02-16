const { prisma } = require('../config/prisma');
const BillService = require('./BillService');

class BillItemService {
  /**
   * Get all bill-item relationships with optional filtering
   * @param {Object} filters - Filter options
   * @param {number} filters.branch_id - Branch ID (required)
   * @param {number} filters.bill_id - Bill ID filter
   * @param {number} filters.item_id - Item ID filter
   * @param {number} filters.limit - Limit results (default: 50)
   * @param {number} filters.offset - Offset for pagination (default: 0)
   * @returns {Promise<Object>} Bill items with pagination info
   */
  async getAllBillItems(filters = {}) {
    const { branch_id, bill_id, item_id, limit = 50, offset = 0 } = filters;

    if (!branch_id) throw new Error('Branch ID is required');

    const prismaWhere = {
      bill: {
        branchId: parseInt(branch_id)
      }
    };
    if (bill_id) prismaWhere.billId = parseInt(bill_id);
    if (item_id) prismaWhere.itemId = parseInt(item_id);

    const billItems = await prisma.billItem.findMany({
      where: prismaWhere,
      include: {
        bill: {
          select: {
            id: true,
            title: true,
            user: {
              select: {
                id: true,
                username: true
              }
            }
          }
        },
        item: { include: { itbisRate: true } }
      },
      orderBy: {
        createdAt: 'desc'
      },
      take: parseInt(limit),
      skip: parseInt(offset)
    });

    const total = await prisma.billItem.count({ where: prismaWhere });

    return {
      billItems,
      total,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };
  }

  /**
   * Get a specific bill-item relationship by ID
   * @param {number} id - Bill-item ID
   * @param {number} branchId - Branch ID (for scope)
   * @returns {Promise<Object|null>} Bill item with related data or null if not found
   */
  async getBillItemById(id, branchId) {
    return await prisma.billItem.findFirst({
      where: {
        id: parseInt(id),
        bill: {
          branchId: parseInt(branchId)
        }
      },
      include: {
        bill: {
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
        item: { include: { itbisRate: true } }
      }
    });
  }

  /**
   * Get all items for a specific bill
   * @param {number} billId - Bill ID
   * @param {number} branchId - Branch ID (for scope)
   * @returns {Promise<Object>} Bill with its items and totals
   */
  async getItemsForBill(billId, branchId) {
    const bill = await prisma.bill.findFirst({
      where: {
        id: parseInt(billId),
        branchId: parseInt(branchId)
      },
      select: {
        id: true,
        title: true,
        amount: true,
        user: {
          select: {
            id: true,
            username: true
          }
        }
      }
    });

    if (!bill) {
      throw new Error('Bill not found');
    }

    const billItems = await prisma.billItem.findMany({
      where: { billId: parseInt(billId) },
      include: {
        item: { include: { itbisRate: true } }
      },
      orderBy: {
        createdAt: 'asc'
      }
    });

    const totalResult = await prisma.billItem.aggregate({
      where: { billId: parseInt(billId) },
      _sum: { totalPrice: true },
      _count: { id: true }
    });

    return {
      bill,
      billItems,
      total_items: totalResult._count.id,
      calculated_total: parseFloat(totalResult._sum.totalPrice || 0)
    };
  }

  /**
   * Get all bills that contain a specific item (branch-scoped)
   * @param {number} itemId - Item ID
   * @param {number} branchId - Branch ID (for scope)
   * @returns {Promise<Object>} Item with bills that contain it
   */
  async getBillsForItem(itemId, branchId) {
    const item = await prisma.item.findFirst({
      where: { id: parseInt(itemId), branchId: parseInt(branchId) }
    });
    if (!item) throw new Error('Item not found');

    const billItems = await prisma.billItem.findMany({
      where: {
        itemId: parseInt(itemId),
        bill: {
          branchId: parseInt(branchId)
        }
      },
      include: {
        bill: {
          include: {
            user: {
              select: {
                id: true,
                username: true
              }
            }
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    return {
      item,
      billItems,
      total_bills: billItems.length
    };
  }

  /**
   * Add an item to a bill
   * @param {Object} billItemData - Bill item data
   * @param {number} branchId - Branch ID (for scope)
   * @returns {Promise<Object>} Created bill item
   */
  async addItemToBill(billItemData, branchId) {
    const { bill_id, item_id, quantity, unit_price, notes } = billItemData;

    if (!branchId) {
      throw new Error('Branch ID is required');
    }

    const billExists = await prisma.bill.findFirst({
      where: {
        id: parseInt(bill_id),
        branchId: parseInt(branchId)
      }
    });

    if (!billExists) {
      throw new Error('Bill not found or does not belong to this branch');
    }

    const itemExists = await prisma.item.findUnique({
      where: { id: parseInt(item_id) }
    });

    if (!itemExists) {
      throw new Error('Item not found');
    }

    if (itemExists.branchId !== billExists.branchId) {
      throw new Error('Item does not belong to the bill\'s branch');
    }

    const existingRelation = await prisma.billItem.findFirst({
      where: {
        billId: parseInt(bill_id),
        itemId: parseInt(item_id)
      }
    });

    if (existingRelation) {
      throw new Error('Item is already associated with this bill');
    }

    const finalUnitPrice = unit_price ?? itemExists.unitPrice;
    const totalPrice = quantity * finalUnitPrice;

    const created = await prisma.billItem.create({
      data: {
        billId: parseInt(bill_id),
        itemId: parseInt(item_id),
        quantity,
        unitPrice: finalUnitPrice,
        totalPrice,
        notes
      },
      include: {
        bill: {
          select: {
            id: true,
            title: true
          }
        },
        item: { include: { itbisRate: true } }
      }
    });
    await BillService.recalculateBillTotals(parseInt(bill_id));
    return created;
  }

  /**
   * Update a bill-item relationship
   * @param {number} id - Bill item ID
   * @param {number} branchId - Branch ID (for scope)
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated bill item
   */
  async updateBillItem(id, branchId, updateData) {
    const existingBillItem = await prisma.billItem.findFirst({
      where: {
        id: parseInt(id),
        bill: {
          branchId: parseInt(branchId)
        }
      }
    });
    if (!existingBillItem) throw new Error('Bill-item relationship not found');

    const updateFields = {};
    if (updateData.quantity !== undefined) updateFields.quantity = updateData.quantity;
    if (updateData.unit_price !== undefined) updateFields.unitPrice = updateData.unit_price;
    if (updateData.notes !== undefined) updateFields.notes = updateData.notes;

    const finalQuantity = updateData.quantity !== undefined ? updateData.quantity : existingBillItem.quantity;
    const finalUnitPrice = updateData.unit_price !== undefined ? updateData.unit_price : existingBillItem.unitPrice;

    if (updateData.quantity !== undefined || updateData.unit_price !== undefined) {
      updateFields.totalPrice = finalQuantity * finalUnitPrice;
    }

    const updated = await prisma.billItem.update({
      where: { id: parseInt(id) },
      data: updateFields,
      include: {
        bill: {
          select: {
            id: true,
            title: true
          }
        },
        item: { include: { itbisRate: true } }
      }
    });
    await BillService.recalculateBillTotals(updated.bill.id);
    return updated;
  }

  /**
   * Remove an item from a bill
   * @param {number} id - Bill item ID
   * @param {number} branchId - Branch ID (for scope)
   * @returns {Promise<Object>} Deletion result
   */
  async removeItemFromBill(id, branchId) {
    const existingBillItem = await prisma.billItem.findFirst({
      where: {
        id: parseInt(id),
        bill: {
          branchId: parseInt(branchId)
        }
      },
      include: {
        bill: { select: { id: true, title: true } },
        item: { select: { id: true, name: true } }
      }
    });
    if (!existingBillItem) throw new Error('Bill-item relationship not found');

    const billId = existingBillItem.bill.id;
    await prisma.billItem.delete({
      where: { id: parseInt(id) }
    });
    await BillService.recalculateBillTotals(billId);

    return {
      message: 'Item removed from bill successfully',
      billItem: existingBillItem
    };
  }

  /**
   * Get bill-item statistics
   * @param {Object} filters - Filter options
   * @param {number} filters.branch_id - Branch ID (required)
   * @param {number} filters.bill_id - Bill ID filter
   * @param {number} filters.item_id - Item ID filter
   * @returns {Promise<Object>} Bill item statistics
   */
  async getBillItemStats(filters = {}) {
    const { branch_id, bill_id, item_id } = filters;

    if (!branch_id) {
      throw new Error('Branch ID is required');
    }

    const where = {
      bill: {
        branchId: parseInt(branch_id)
      }
    };
    if (bill_id) where.billId = parseInt(bill_id);
    if (item_id) where.itemId = parseInt(item_id);

    const stats = await prisma.billItem.aggregate({
      where,
      _count: { id: true },
      _sum: {
        quantity: true,
        totalPrice: true
      },
      _avg: {
        quantity: true,
        unitPrice: true,
        totalPrice: true
      }
    });

    return {
      total_relationships: stats._count.id,
      total_quantity: stats._sum.quantity || 0,
      total_amount: parseFloat(stats._sum.totalPrice || 0),
      average_quantity: parseFloat(stats._avg.quantity || 0),
      average_unit_price: parseFloat(stats._avg.unitPrice || 0),
      average_total_price: parseFloat(stats._avg.totalPrice || 0)
    };
  }

  /**
   * Bulk add items to a bill
   * @param {number} billId - Bill ID
   * @param {number} branchId - Branch ID (for scope)
   * @param {Array} items - Array of items to add
   * @returns {Promise<Array>} Created bill items
   */
  async bulkAddItemsToBill(billId, branchId, items) {
    if (!branchId) throw new Error('Branch ID is required');

    const billExists = await prisma.bill.findFirst({
      where: {
        id: parseInt(billId),
        branchId: parseInt(branchId)
      }
    });
    if (!billExists) throw new Error('Bill not found or does not belong to this branch');

    const itemIds = items.map(item => item.item_id);
    const existingItems = await prisma.item.findMany({
      where: { id: { in: itemIds }, branchId: parseInt(branchId) }
    });
    if (existingItems.length !== itemIds.length) {
      throw new Error('One or more items not found');
    }

    const existingRelations = await prisma.billItem.findMany({
      where: {
        billId: parseInt(billId),
        itemId: { in: itemIds }
      }
    });

    if (existingRelations.length > 0) {
      const existingItemIds = existingRelations.map(rel => rel.itemId);
      throw new Error(`Items with IDs ${existingItemIds.join(', ')} are already associated with this bill`);
    }

    const billItemsData = items.map(item => {
      const existingItem = existingItems.find(ei => ei.id === item.item_id);
      const finalUnitPrice = item.unit_price ?? existingItem.unitPrice;
      const totalPrice = item.quantity * finalUnitPrice;
      return {
        billId: parseInt(billId),
        itemId: item.item_id,
        quantity: item.quantity,
        unitPrice: finalUnitPrice,
        totalPrice,
        notes: item.notes || null
      };
    });

    await prisma.billItem.createMany({
      data: billItemsData
    });
    await BillService.recalculateBillTotals(parseInt(billId));

    return await prisma.billItem.findMany({
      where: {
        billId: parseInt(billId),
        itemId: { in: itemIds }
      },
      include: {
        bill: { select: { id: true, title: true } },
        item: { include: { itbisRate: true } }
      }
    });
  }

  async getBillTotal(billId) {
    const result = await prisma.billItem.aggregate({
      where: { billId: parseInt(billId) },
      _sum: { totalPrice: true }
    });
    return parseFloat(result._sum.totalPrice || 0);
  }
}

module.exports = new BillItemService();
