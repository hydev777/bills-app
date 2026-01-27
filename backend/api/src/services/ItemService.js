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
    const { category, search, limit = 50, offset = 0 } = filters;

    const where = {};
    if (category) {
      where.categoryId = parseInt(category);
    }
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } }
      ];
    }

    const items = await prisma.item.findMany({
      where,
      include: {
        billItems: {
          select: {
            id: true,
            quantity: true,
            totalPrice: true,
            bill: {
              select: {
                id: true,
                title: true
              }
            }
          }
        },
        _count: {
          billItems: true
        }
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
  async getItemById(id) {
    return await prisma.item.findUnique({
      where: { id: parseInt(id) },
      include: {
        billItems: {
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
            }
          },
          orderBy: { createdAt: 'desc' }
        },
        _count: {
          billItems: true
        }
      }
    });
  }

  /**
   * Create a new item
   * @param {Object} itemData - Item data
   * @returns {Promise<Object>} Created item
   */
  async createItem(itemData) {
    const { name, description, unit_price, category_id } = itemData;

    const existingItem = await prisma.item.findFirst({
      where: {
        name: { equals: name, mode: 'insensitive' }
      }
    });

    if (existingItem) {
      throw new Error('Item with this name already exists');
    }

    if (category_id) {
      const category = await prisma.itemCategory.findUnique({
        where: { id: parseInt(category_id) }
      });
      if (!category) {
        throw new Error('Category not found');
      }
    }

    return await prisma.item.create({
      data: {
        name,
        description: description || null,
        unitPrice: unit_price,
        categoryId: category_id || null
      },
      include: {
        category: true,
        _count: {
          billItems: true
        }
      }
    });
  }

  /**
   * Update an existing item
   * @param {number} id - Item ID
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated item
   */
  async updateItem(id, updateData) {
    const { name, description, unit_price, category_id } = updateData;

    const existingItem = await prisma.item.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingItem) {
      throw new Error('Item not found');
    }

    if (category_id !== undefined && category_id !== null) {
      const category = await prisma.itemCategory.findUnique({
        where: { id: parseInt(category_id) }
      });
      if (!category) {
        throw new Error('Category not found');
      }
    }

    if (name && name.toLowerCase() !== existingItem.name.toLowerCase()) {
      const duplicateItem = await prisma.item.findFirst({
        where: {
          name: { equals: name, mode: 'insensitive' },
          id: { not: parseInt(id) }
        }
      });
      if (duplicateItem) {
        throw new Error('Item with this name already exists');
      }
    }

    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (description !== undefined) updateFields.description = description || null;
    if (unit_price !== undefined) updateFields.unitPrice = unit_price;
    if (category_id !== undefined) updateFields.categoryId = category_id || null;

    return await prisma.item.update({
      where: { id: parseInt(id) },
      data: updateFields,
      include: {
        category: true,
        billItems: {
          select: {
            id: true,
            quantity: true,
            totalPrice: true,
            bill: {
              select: {
                id: true,
                title: true
              }
            }
          }
        },
        _count: {
          billItems: true
        }
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
      where: { id: parseInt(id) },
      include: {
        _count: {
          billItems: true
        }
      }
    });

    if (!existingItem) {
      throw new Error('Item not found');
    }

    if (existingItem._count.billItems > 0) {
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
  async getItemStats(id) {
    const item = await prisma.item.findUnique({
      where: { id: parseInt(id) },
      include: {
        billItems: {
          include: {
            bill: {
              select: {
                id: true,
                amount: true
              }
            }
          }
        }
      }
    });

    if (!item) {
      throw new Error('Item not found');
    }

    const totalRevenue = item.billItems.reduce((sum, bi) => sum + parseFloat(bi.totalPrice), 0);
    const totalQty = item.billItems.reduce((sum, bi) => sum + bi.quantity, 0);

    return {
      totalUsage: item.billItems.length,
      totalRevenue,
      averageQuantity: item.billItems.length > 0 ? totalQty / item.billItems.length : 0,
      recentUsage: item.billItems
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
