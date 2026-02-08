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
    const { organization_id, category, search, limit = 50, offset = 0 } = filters;

    if (!organization_id) throw new Error('Organization ID is required');

    const where = { organizationId: parseInt(organization_id) };
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
  async getItemById(id, organizationId) {
    return await prisma.item.findFirst({
      where: { id: parseInt(id), organizationId: parseInt(organizationId) },
      include: {
        itbisRate: { select: { id: true, name: true, percentage: true } },
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
    const { organization_id, name, description, unit_price, category_id, itbis_rate_id } = itemData;

    if (!organization_id) throw new Error('Organization ID is required');
    if (!itbis_rate_id) throw new Error('ITBIS rate is required');

    const existingItem = await prisma.item.findFirst({
      where: {
        organizationId: parseInt(organization_id),
        name: { equals: name, mode: 'insensitive' }
      }
    });
    if (existingItem) throw new Error('Item with this name already exists in this organization');

    const itbisRate = await prisma.itbisRate.findUnique({
      where: { id: parseInt(itbis_rate_id) }
    });
    if (!itbisRate) throw new Error('ITBIS rate not found');

    if (category_id) {
      const category = await prisma.itemCategory.findFirst({
        where: { id: parseInt(category_id), organizationId: parseInt(organization_id) }
      });
      if (!category) throw new Error('Category not found');
    }

    return await prisma.item.create({
      data: {
        organizationId: parseInt(organization_id),
        name,
        description: description || null,
        unitPrice: unit_price,
        categoryId: category_id || null,
        itbisRateId: parseInt(itbis_rate_id)
      },
      include: {
        category: true,
        itbisRate: { select: { id: true, name: true, percentage: true } },
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
  async updateItem(id, organizationId, updateData) {
    const { name, description, unit_price, category_id, itbis_rate_id } = updateData;

    const existingItem = await prisma.item.findFirst({
      where: { id: parseInt(id), organizationId: parseInt(organizationId) }
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
        where: { id: parseInt(category_id), organizationId: parseInt(organizationId) }
      });
      if (!category) throw new Error('Category not found');
    }

    if (name && name.toLowerCase() !== existingItem.name.toLowerCase()) {
      const duplicateItem = await prisma.item.findFirst({
        where: {
          organizationId: parseInt(organizationId),
          name: { equals: name, mode: 'insensitive' },
          id: { not: parseInt(id) }
        }
      });
      if (duplicateItem) throw new Error('Item with this name already exists in this organization');
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
        itbisRate: { select: { id: true, name: true, percentage: true } },
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
  async getItemStats(id, organizationId) {
    const item = await prisma.item.findFirst({
      where: { id: parseInt(id), organizationId: parseInt(organizationId) },
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
