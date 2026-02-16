const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { BillService } = require('../services');
const { authenticateToken, requirePrivilege } = require('../middleware/auth');
const { validateBranch } = require('../middleware/branch');

// Allowed bill statuses
const BILL_STATUSES = ['draft', 'issued', 'paid', 'cancelled'];

const billSchema = Joi.object({
  title: Joi.string().min(1).max(100).required(),
  description: Joi.string().max(500).allow(''),
  amount: Joi.number().min(0).precision(2).allow(0).default(0),
  status: Joi.string().valid(...BILL_STATUSES).default('draft'),
  client_id: Joi.number().integer().positive().allow(null)
});

const updateBillSchema = Joi.object({
  title: Joi.string().min(1).max(100),
  description: Joi.string().max(500).allow(''),
  status: Joi.string().valid(...BILL_STATUSES),
  client_id: Joi.number().integer().positive().allow(null)
});

// GET /api/bills - Get all bills (branch-scoped). Requires X-Branch-Id. Optional query: status, user_id, client_id
router.get('/', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const { limit = 50, offset = 0, user_id, status, client_id } = req.query;
    const filters = { branch_id: req.branchId, user_id: user_id || undefined, status: status || undefined, client_id: client_id || undefined, limit, offset };
    const result = await BillService.getAllBills(filters);
    res.json(result);
  } catch (error) {
    console.error('Error fetching bills:', error);
    res.status(500).json({ error: 'Failed to fetch bills' });
  }
});

// GET /api/bills/stats/summary - Get bills summary (must be before /:id). Requires X-Branch-Id
router.get('/stats/summary', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const stats = await BillService.getBillStats(req.branchId);
    res.json(stats);
  } catch (error) {
    console.error('Error fetching bill stats:', error);
    res.status(500).json({ error: 'Failed to fetch bill statistics' });
  }
});

// GET /api/bills/public/:publicId - Get a bill by its unique public ID. Requires X-Branch-Id
router.get('/public/:publicId', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const bill = await BillService.getBillByPublicId(req.params.publicId, req.branchId);
    if (!bill) return res.status(404).json({ error: 'Bill not found' });
    res.json(bill);
  } catch (error) {
    console.error('Error fetching bill by publicId:', error);
    res.status(500).json({ error: 'Failed to fetch bill' });
  }
});

// GET /api/bills/:id - Get a specific bill. Requires X-Branch-Id
router.get('/:id', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const bill = await BillService.getBillById(id, req.branchId);
    if (!bill) return res.status(404).json({ error: 'Bill not found' });
    res.json(bill);
  } catch (error) {
    console.error('Error fetching bill:', error);
    res.status(500).json({ error: 'Failed to fetch bill' });
  }
});

// POST /api/bills - Create a new bill. Requires X-Branch-Id
router.post('/', authenticateToken, validateBranch, requirePrivilege('bill', 'create'), async (req, res) => {
  try {
    const { error, value } = billSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    value.user_id = req.userId;
    value.branch_id = req.branchId;
    const bill = await BillService.createBill(value);
    res.status(201).json(bill);
  } catch (error) {
    console.error('Error creating bill:', error);
    if (error.message === 'User not found' || error.message === 'Client not found' || error.message === 'Branch not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to create bill' });
  }
});

// PUT /api/bills/:id - Update a bill. Requires X-Branch-Id
router.put('/:id', authenticateToken, validateBranch, requirePrivilege('bill', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = updateBillSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const bill = await BillService.updateBill(id, req.branchId, value);
    res.json(bill);
  } catch (error) {
    console.error('Error updating bill:', error);
    if (error.message === 'Bill not found' || error.message === 'Client not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to update bill' });
  }
});

// DELETE /api/bills/:id - Delete a bill. Requires X-Branch-Id
router.delete('/:id', authenticateToken, validateBranch, requirePrivilege('bill', 'delete'), async (req, res) => {
  try {
    const { id } = req.params;
    const result = await BillService.deleteBill(id, req.branchId);
    res.json(result);
  } catch (error) {
    console.error('Error deleting bill:', error);
    if (error.message === 'Bill not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to delete bill' });
  }
});

module.exports = router;
