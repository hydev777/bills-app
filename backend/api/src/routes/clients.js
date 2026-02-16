const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { ClientService } = require('../services');
const { authenticateToken, requirePrivilege } = require('../middleware/auth');
const clientSchema = Joi.object({
  name: Joi.string().min(1).max(100).required(),
  identifier: Joi.string().max(50).allow('', null),
  tax_id: Joi.string().max(50).allow('', null),
  email: Joi.string().max(100).email().allow('', null),
  phone: Joi.string().max(20).allow('', null),
  address: Joi.string().max(500).allow('', null)
});

const updateClientSchema = Joi.object({
  name: Joi.string().min(1).max(100),
  identifier: Joi.string().max(50).allow('', null),
  tax_id: Joi.string().max(50).allow('', null),
  email: Joi.string().max(100).email().allow('', null),
  phone: Joi.string().max(20).allow('', null),
  address: Joi.string().max(500).allow('', null)
});

// GET /api/clients - List all clients (global; query: search, limit, offset)
router.get('/', authenticateToken, requirePrivilege('client', 'read'), async (req, res) => {
  try {
    const { search, limit = 50, offset = 0 } = req.query;
    const result = await ClientService.getAllClients({ search, limit, offset });
    res.json(result);
  } catch (error) {
    console.error('Error fetching clients:', error);
    res.status(500).json({ error: 'Failed to fetch clients' });
  }
});

// GET /api/clients/:id - Get one client
router.get('/:id', authenticateToken, requirePrivilege('client', 'read'), async (req, res) => {
  try {
    const client = await ClientService.getClientById(req.params.id);
    if (!client) return res.status(404).json({ error: 'Client not found' });
    res.json(client);
  } catch (error) {
    console.error('Error fetching client:', error);
    res.status(500).json({ error: 'Failed to fetch client' });
  }
});

// POST /api/clients - Create client
router.post('/', authenticateToken, requirePrivilege('client', 'create'), async (req, res) => {
  try {
    const { error, value } = clientSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const client = await ClientService.createClient(value);
    res.status(201).json(client);
  } catch (error) {
    console.error('Error creating client:', error);
    if (error.message === 'Client name is required') return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to create client' });
  }
});

// PUT /api/clients/:id - Update client
router.put('/:id', authenticateToken, requirePrivilege('client', 'update'), async (req, res) => {
  try {
    const { error, value } = updateClientSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const client = await ClientService.updateClient(req.params.id, value);
    res.json(client);
  } catch (error) {
    console.error('Error updating client:', error);
    if (error.message === 'Client not found') return res.status(404).json({ error: error.message });
    if (error.message === 'Client name cannot be empty') return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to update client' });
  }
});

// DELETE /api/clients/:id - Delete client
router.delete('/:id', authenticateToken, requirePrivilege('client', 'delete'), async (req, res) => {
  try {
    const result = await ClientService.deleteClient(req.params.id);
    res.json(result);
  } catch (error) {
    console.error('Error deleting client:', error);
    if (error.message === 'Client not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to delete client' });
  }
});

module.exports = router;
