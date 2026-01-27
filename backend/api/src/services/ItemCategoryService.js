const { prisma } = require('../config/prisma');

class ItemCategoryService {
  /**
   * Get all item categories
   * @param {Object} options - Query options
   * @param {number} options.organizationId - Organization ID (required)
   * @param {number} options.limit - Limit results (default: 50)
   * @param {number} options.offset - Offset for pagination (default: 0)
   * @param {boolean} options.includeItemCount - Include count of items per category
   * @returns {Promise<Object>} Categories with pagination info
   */
  async getAllCategories(options = {}) {
    const { limit = 50, offset = 0, includeItemCount = false } = options;

    const include = {};
    if (includeItemCount) {
      include._count = { items: true };
    }

    const categories = await prisma.itemCategory.findMany({
      include,
      orderBy: { name: 'asc' },
      take: parseInt(limit),
      skip: parseInt(offset)
    });

    const total = await prisma.itemCategory.count();

    return {
      categories,
      total,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };
  }

  /**
   * Get a specific category by ID
   * @param {number} id - Category ID
   * @param {number} organizationId - Organization ID (for security)
   * @param {boolean} includeItems - Include related items
   * @returns {Promise<Object|null>} Category with related data or null if not found
   */
  async getCategoryById(id, includeItems = false) {
    const include = {
      _count: { items: true }
    };
    if (includeItems) {
      include.items = { orderBy: { name: 'asc' } };
    }

    return await prisma.itemCategory.findUnique({
      where: { id: parseInt(id) },
      include
    });
  }

  /**
   * Get a category by name
   * @param {string} name - Category name
   * @returns {Promise<Object|null>} Category or null if not found
   */
  async getCategoryByName(name) {
    return await prisma.itemCategory.findUnique({
      where: { name },
      include: { _count: { items: true } }
    });
  }

  /**
   * Create a new category
   * @param {Object} categoryData - Category data
   * @param {number} categoryData.organization_id - Organization ID (required)
   * @param {string} categoryData.name - Category name
   * @param {string} categoryData.description - Category description
   * @returns {Promise<Object>} Created category
   */
  async createCategory(categoryData) {
    const { name, description } = categoryData;

    const existingCategory = await prisma.itemCategory.findUnique({
      where: { name }
    });

    if (existingCategory) {
      throw new Error('Category with this name already exists');
    }

    return await prisma.itemCategory.create({
      data: {
        name,
        description: description || null
      },
      include: {
        _count: { items: true }
      }
    });
  }

  /**
   * Update an existing category
   * @param {number} id - Category ID
   * @param {Object} updateData - Update data
   * @returns {Promise<Object>} Updated category
   */
  async updateCategory(id, updateData) {
    const { name, description } = updateData;

    const existingCategory = await prisma.itemCategory.findUnique({
      where: { id: parseInt(id) }
    });

    if (!existingCategory) {
      throw new Error('Category not found');
    }

    if (name && name !== existingCategory.name) {
      const duplicate = await prisma.itemCategory.findUnique({
        where: { name }
      });
      if (duplicate) {
        throw new Error('Category with this name already exists');
      }
    }

    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (description !== undefined) updateFields.description = description || null;

    return await prisma.itemCategory.update({
      where: { id: parseInt(id) },
      data: updateFields,
      include: {
        _count: { items: true }
      }
    });
  }

  /**
   * Delete a category
   * @param {number} id - Category ID
   * @param {number} organizationId - Organization ID (for security)
   * @returns {Promise<Object>} Deleted category
   */
  async deleteCategory(id) {
    const existingCategory = await prisma.itemCategory.findUnique({
      where: { id: parseInt(id) },
      include: {
        _count: { items: true }
      }
    });

    if (!existingCategory) {
      throw new Error('Category not found');
    }

    if (existingCategory._count.items > 0) {
      throw new Error('Cannot delete category that is being used by items');
    }

    return await prisma.itemCategory.delete({
      where: { id: parseInt(id) }
    });
  }

  /**
   * Get category statistics
   * @param {number} id - Category ID
   * @param {number} organizationId - Organization ID (for security)
   * @returns {Promise<Object>} Category usage statistics
   */
  async getCategoryStats(id) {
    const category = await prisma.itemCategory.findUnique({
      where: { id: parseInt(id) },
      include: {
        items: {
          include: {
            billItems: {
              include: {
                bill: { select: { amount: true } }
              }
            }
          }
        }
      }
    });

    if (!category) {
      throw new Error('Category not found');
    }

    const totalUsage = category.items.reduce((sum, item) => sum + item.billItems.length, 0);
    const totalRevenue = category.items.reduce((sum, item) => {
      return sum + item.billItems.reduce((s, bi) => s + parseFloat(bi.totalPrice), 0);
    }, 0);
    const avgPrice = category.items.length > 0
      ? category.items.reduce((s, i) => s + parseFloat(i.unitPrice), 0) / category.items.length
      : 0;

    const mostUsedItems = category.items
      .map(item => ({
        id: item.id,
        name: item.name,
        unitPrice: item.unitPrice,
        usageCount: item.billItems.length,
        totalRevenue: item.billItems.reduce((s, bi) => s + parseFloat(bi.totalPrice), 0)
      }))
      .sort((a, b) => b.usageCount - a.usageCount)
      .slice(0, 5);

    return {
      itemCount: category.items.length,
      totalUsage,
      totalRevenue,
      averageItemPrice: avgPrice,
      mostUsedItems
    };
  }

  /**
   * Move items from one category to another
   * @param {number} fromCategoryId - Source category ID
   * @param {number} toCategoryId - Target category ID
   * @returns {Promise<Object>} Update result
   */
  async moveItemsToCategory(fromCategoryId, toCategoryId) {
    // Verify both categories exist
    const [fromCategory, toCategory] = await Promise.all([
      prisma.itemCategory.findUnique({ where: { id: parseInt(fromCategoryId) } }),
      prisma.itemCategory.findUnique({ where: { id: parseInt(toCategoryId) } })
    ]);

    if (!fromCategory) {
      throw new Error('Source category not found');
    }

    if (!toCategory) {
      throw new Error('Target category not found');
    }

    // Update all items from source category to target category
    const result = await prisma.item.updateMany({
      where: { categoryId: parseInt(fromCategoryId) },
      data: { categoryId: parseInt(toCategoryId) }
    });

    return {
      movedItemsCount: result.count,
      fromCategory: fromCategory.name,
      toCategory: toCategory.name
    };
  }
}

module.exports = new ItemCategoryService();
