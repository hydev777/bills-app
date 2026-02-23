const { prisma } = require('../config/prisma');

class ItemService {
  /**
   * Get all items with optional filtering
   * @param {Object} filters - Filter options
   * @param {string} filters.category - Category ID filter
   * @param {string} filters.search - Search term for name/description
   * @param {number} filters.limit - Limit results (default: 50)
   * @param {number} filters.offset - Offset for pagination (default: 0)
   * @returns {Promise<Object>} Items with pagination info
   */
  async getAllItems(filters = {}) {
    const { branch_id, category, search, limit = 50, offset = 0 } = filters;

    if (!branch_id) throw new Error('Branch ID is required');

    const where = { branchId: parseInt(branch_id) };
    if (category) where.categoryId = parseInt(category);
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } }
      ];
    }

    const items = await prisma.item.findMany({
      where,
      include: {
        itbisRate: { select: { id: true, name: true, percentage: true } },
        category: { select: { id: true, name: true } }
      },
      orderBy: { name: 'asc' },
      take: parseInt(limit),
      skip: parseInt(offset)
    });

    const total = await prisma.item.count({ where });

    return {
      items,
      total,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };
  }

  /**
   * Get a specific item by ID
   * @param {number} id - Item ID
   * @returns {Promise<Object|null>} Item with related data or null if not found
   */
  async getItemById(id, branchId) {
    return await prisma.item.findFirst({
      where: { id: parseInt(id), branchId: parseInt(branchId) },
      include: {
        itbisRate: { select: { id: true, name: true, percentage: true } },
        category: { select: { id: true, name: true } }
      }
    });
  }

  /**
   * Create a new item
   * @param {Object} itemData - Item data
   * @returns {Promise<Object>} Created item
   */
  async createItem(itemData) {
    const { branch_id, name, description, unit_price, category_id, itbis_rate_id } = itemData;

    if (!branch_id) throw new Error('Branch ID is required');
    if (!itbis_rate_id) throw new Error('ITBIS rate is required');

    const existingItem = await prisma.item.findFirst({
      where: {
        branchId: parseInt(branch_id),
        name: { equals: name, mode: 'insensitive' }
      }
    });
    if (existingItem) throw new Error('Item with this name already exists in this branch');

    const itbisRate = await prisma.itbisRate.findUnique({
      where: { id: parseInt(itbis_rate_id) }
    });
    if (!itbisRate) throw new Error('ITBIS rate not found');

    if (category_id) {
      const category = await prisma.itemCategory.findFirst({
        where: { id: parseInt(category_id), branchId: parseInt(branch_id) }
      });
      if (!category) throw new Error('Category not found');
    }

    return await prisma.item.create({
      data: {
        branchId: parseInt(branch_id),
        name,
        description: description || null,
        unitPrice: unit_price,
        categoryId: category_id || null,
        itbisRateId: parseInt(itbis_rate_id)
      },
      include: {
        category: true,
        itbisRate: { select: { id: true, name: true, percentage: true } }
      }
    });
  }

  /**
   * Update an existing item
   * @param {number} id - Item ID
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated item
   */
  async updateItem(id, branchId, updateData) {
    const { name, description, unit_price, category_id, itbis_rate_id } = updateData;

    const existingItem = await prisma.item.findFirst({
      where: { id: parseInt(id), branchId: parseInt(branchId) }
    });
    if (!existingItem) throw new Error('Item not found');

    if (itbis_rate_id !== undefined) {
      const itbisRate = await prisma.itbisRate.findUnique({
        where: { id: parseInt(itbis_rate_id) }
      });
      if (!itbisRate) throw new Error('ITBIS rate not found');
    }

    if (category_id !== undefined && category_id !== null) {
      const category = await prisma.itemCategory.findFirst({
        where: { id: parseInt(category_id), branchId: parseInt(branchId) }
      });
      if (!category) throw new Error('Category not found');
    }

    if (name && name.toLowerCase() !== existingItem.name.toLowerCase()) {
      const duplicateItem = await prisma.item.findFirst({
        where: {
          branchId: parseInt(branchId),
          name: { equals: name, mode: 'insensitive' },
          id: { not: parseInt(id) }
        }
      });
      if (duplicateItem) throw new Error('Item with this name already exists in this branch');
    }

    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (description !== undefined) updateFields.description = description || null;
    if (unit_price !== undefined) updateFields.unitPrice = unit_price;
    if (category_id !== undefined) updateFields.categoryId = category_id || null;
    if (itbis_rate_id !== undefined) updateFields.itbisRateId = parseInt(itbis_rate_id);

    return await prisma.item.update({
      where: { id: parseInt(id) },
      data: updateFields,
      include: {
        category: true,
        itbisRate: { select: { id: true, name: true, percentage: true } }
      }
    });
  }

  /**
   * Delete an item
   * @param {number} id - Item ID
   * @returns {Promise<Object>} Deleted item
   */
  async deleteItem(id) {
    const existingItem = await prisma.item.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingItem) {
      throw new Error('Item not found');
    }

    const billItemsCount = await prisma.billItem.count({
      where: { itemId: parseInt(id) }
    });
    if (billItemsCount > 0) {
      throw new Error('Cannot delete item that is being used in bills');
    }

    await prisma.item.delete({
      where: { id: parseInt(id) }
    });

    return {
      message: 'Item deleted successfully',
      id: parseInt(id)
    };
  }

  /**
   * Get item statistics
   * @param {number} id - Item ID
   * @returns {Promise<Object>} Item usage statistics
   */
  async getItemStats(id, branchId) {
    const item = await prisma.item.findFirst({
      where: { id: parseInt(id), branchId: parseInt(branchId) }
    });

    if (!item) {
      throw new Error('Item not found');
    }

    const billItems = await prisma.billItem.findMany({
      where: { itemId: parseInt(id) },
      include: {
        bill: { select: { id: true, amount: true } }
      }
    });

    const totalRevenue = billItems.reduce((sum, bi) => sum + parseFloat(bi.totalPrice), 0);
    const totalQty = billItems.reduce((sum, bi) => sum + bi.quantity, 0);

    return {
      totalUsage: billItems.length,
      totalRevenue,
      averageQuantity: billItems.length > 0 ? totalQty / billItems.length : 0,
      recentUsage: billItems
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
        .slice(0, 5)
        .map(bi => ({
          billId: bi.bill.id,
          quantity: bi.quantity,
          totalPrice: bi.totalPrice
        }))
    };
  }
}

module.exports = new ItemService();
