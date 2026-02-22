const { prisma } = require('../config/prisma');

class ClientService {
  /**
   * Get all clients (global list, no organization filter). Pagination and search.
   * @param {Object} filters - { search, limit, offset }
   * @returns {Promise<Object>} { clients, total, limit, offset }
   */
  async getAllClients(filters = {}) {
    const { search, limit = 50, offset = 0 } = filters;
    const take = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
    const skip = Math.max(0, parseInt(offset, 10) || 0);

    const where = {};
    if (search && search.trim()) {
      const term = search.trim();
      where.OR = [
        { name: { contains: term, mode: 'insensitive' } },
        { identifier: { contains: term, mode: 'insensitive' } },
        { taxId: { contains: term, mode: 'insensitive' } },
        { email: { contains: term, mode: 'insensitive' } }
      ];
    }

    const clients = await prisma.client.findMany({
      where,
      orderBy: { name: 'asc' },
      take,
      skip
    });

    const total = await prisma.client.count({ where });

    return {
      clients,
      total,
      limit: take,
      offset: skip
    };
  }

  /**
   * Get one client by ID (global, no org check).
   * @param {number} id - Client ID
   * @returns {Promise<Object|null>}
   */
  async getClientById(id) {
    const parsed = parseInt(id, 10);
    if (Number.isNaN(parsed) || parsed < 1) return null;
    return await prisma.client.findUnique({
      where: { id: parsed }
    });
  }

  /**
   * Create a client (global).
   * @param {Object} data - { name, identifier?, email?, phone?, address? }
   * @returns {Promise<Object>}
   */
  async createClient(data) {
    const { name, identifier, tax_id, email, phone, address } = data;
    if (!name || !name.trim()) throw new Error('Client name is required');

    return await prisma.client.create({
      data: {
        name: name.trim(),
        identifier: identifier?.trim() || null,
        taxId: tax_id?.trim() || null,
        email: email?.trim() || null,
        phone: phone?.trim() || null,
        address: address?.trim() || null
      }
    });
  }

  /**
   * Update a client by ID (global).
   * @param {number} id - Client ID
   * @param {Object} data - Partial client data
   * @returns {Promise<Object>}
   */
  async updateClient(id, data) {
    const parsed = parseInt(id, 10);
    if (Number.isNaN(parsed) || parsed < 1) throw new Error('Client not found');
    const existing = await prisma.client.findUnique({
      where: { id: parsed }
    });
    if (!existing) throw new Error('Client not found');

    const updateFields = {};
    if (data.name !== undefined) {
      const nameTrimmed = data.name.trim();
      if (!nameTrimmed) throw new Error('Client name cannot be empty');
      updateFields.name = nameTrimmed;
    }
    if (data.identifier !== undefined) updateFields.identifier = data.identifier?.trim() || null;
    if (data.tax_id !== undefined) updateFields.taxId = data.tax_id?.trim() || null;
    if (data.email !== undefined) updateFields.email = data.email?.trim() || null;
    if (data.phone !== undefined) updateFields.phone = data.phone?.trim() || null;
    if (data.address !== undefined) updateFields.address = data.address?.trim() || null;

    if (Object.keys(updateFields).length === 0) return existing;

    return await prisma.client.update({
      where: { id: parsed },
      data: updateFields
    });
  }

  /**
   * Delete a client by ID. Fails if the client has any associated bills.
   * @param {number} id - Client ID
   * @returns {Promise<Object>}
   */
  async deleteClient(id) {
    const parsed = parseInt(id, 10);
    if (Number.isNaN(parsed) || parsed < 1) throw new Error('Client not found');
    const existing = await prisma.client.findUnique({
      where: { id: parsed }
    });
    if (!existing) throw new Error('Client not found');

    const billsCount = await prisma.bill.count({
      where: { clientId: parsed }
    });
    if (billsCount > 0) {
      throw new Error('Cannot delete client that has associated bills');
    }

    await prisma.client.delete({
      where: { id: parsed }
    });
    return { message: 'Client deleted successfully', id: parsed };
  }
}

module.exports = new ClientService();
