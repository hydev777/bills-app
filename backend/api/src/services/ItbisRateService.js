const { prisma } = require('../config/prisma');

class ItbisRateService {
  /**
   * Get all ITBIS rates (for dropdowns when creating/editing products)
   * @returns {Promise<Array>} List of itbis rates
   */
  async getAll() {
    return await prisma.itbisRate.findMany({
      orderBy: { percentage: 'asc' },
      select: {
        id: true,
        name: true,
        percentage: true,
        createdAt: true
      }
    });
  }

  /**
   * Get one ITBIS rate by ID
   * @param {number} id - ItbisRate ID
   * @returns {Promise<Object|null>}
   */
  async getById(id) {
    return await prisma.itbisRate.findUnique({
      where: { id: parseInt(id) },
      select: {
        id: true,
        name: true,
        percentage: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }
}

module.exports = new ItbisRateService();
