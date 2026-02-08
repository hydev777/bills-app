const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { BillService } = require('../services');
const { authenticateToken, requirePrivilege } = require('../middleware/auth');
const { validateOrganization } = require('../middleware/organization');

// Allowed bill statuses
const BILL_STATUSES = ['draft', 'issued', 'paid', 'cancelled'];

const billSchema = Joi.object({
  title: Joi.string().min(1).max(100).required(),
  description: Joi.string().max(500).allow(''),
  amount: Joi.number().positive().precision(2).required(),
  status: Joi.string().valid(...BILL_STATUSES).default('draft')
});

const updateBillSchema = Joi.object({
  title: Joi.string().min(1).max(100),
  description: Joi.string().max(500).allow(''),
  amount: Joi.number().positive().precision(2),
  status: Joi.string().valid(...BILL_STATUSES)
});

// GET /api/bills - Get all bills (org-scoped). Optional query: status (draft|issued|paid|cancelled), user_id
router.get('/', authenticateToken, validateOrganization, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const { limit = 50, offset = 0, user_id, status } = req.query;
    const filters = { organization_id: req.organizationId, user_id: user_id || undefined, status: status || undefined, limit, offset };
    const result = await BillService.getAllBills(filters);
    res.json(result);
  } catch (error) {
    console.error('Error fetching bills:', error);
    res.status(500).json({ error: 'Failed to fetch bills' });
  }
});

// GET /api/bills/stats/summary - Get bills summary (must be before /:id)
router.get('/stats/summary', authenticateToken, validateOrganization, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const stats = await BillService.getBillStats(req.organizationId);
    res.json(stats);
  } catch (error) {
    console.error('Error fetching bill stats:', error);
    res.status(500).json({ error: 'Failed to fetch bill statistics' });
  }
});

// GET /api/bills/public/:publicId - Get a bill by its unique public ID
router.get('/public/:publicId', authenticateToken, validateOrganization, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const bill = await BillService.getBillByPublicId(req.params.publicId, req.organizationId);
    if (!bill) return res.status(404).json({ error: 'Bill not found' });
    res.json(bill);
  } catch (error) {
    console.error('Error fetching bill by publicId:', error);
    res.status(500).json({ error: 'Failed to fetch bill' });
  }
});

// GET /api/bills/:id - Get a specific bill
router.get('/:id', authenticateToken, validateOrganization, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const bill = await BillService.getBillById(id, req.organizationId);
    if (!bill) return res.status(404).json({ error: 'Bill not found' });
    res.json(bill);
  } catch (error) {
    console.error('Error fetching bill:', error);
    res.status(500).json({ error: 'Failed to fetch bill' });
  }
});

// POST /api/bills - Create a new bill
router.post('/', authenticateToken, validateOrganization, requirePrivilege('bill', 'create'), async (req, res) => {
  try {
    const { error, value } = billSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    value.user_id = req.userId;
    value.organization_id = req.organizationId;
    const bill = await BillService.createBill(value);
    res.status(201).json(bill);
  } catch (error) {
    console.error('Error creating bill:', error);
    if (error.message === 'User not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to create bill' });
  }
});

// PUT /api/bills/:id - Update a bill
router.put('/:id', authenticateToken, validateOrganization, requirePrivilege('bill', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = updateBillSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const bill = await BillService.updateBill(id, req.organizationId, value);
    res.json(bill);
  } catch (error) {
    console.error('Error updating bill:', error);
    if (error.message === 'Bill not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to update bill' });
  }
});

// DELETE /api/bills/:id - Delete a bill
router.delete('/:id', authenticateToken, validateOrganization, requirePrivilege('bill', 'delete'), async (req, res) => {
  try {
    const { id } = req.params;
    const result = await BillService.deleteBill(id, req.organizationId);
    res.json(result);
  } catch (error) {
    console.error('Error deleting bill:', error);
    if (error.message === 'Bill not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to delete bill' });
  }
});

module.exports = router;
