const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { BillItemService } = require('../services');
const { authenticateToken, requirePrivilege } = require('../middleware/auth');
const { validateBranch } = require('../middleware/branch');

const billItemSchema = Joi.object({
  bill_id: Joi.number().integer().positive().required(),
  item_id: Joi.number().integer().positive().required(),
  quantity: Joi.number().integer().positive().default(1),
  unit_price: Joi.number().positive().precision(2),
  notes: Joi.string().max(500).allow('')
});

const updateBillItemSchema = Joi.object({
  quantity: Joi.number().integer().positive(),
  unit_price: Joi.number().positive().precision(2),
  notes: Joi.string().max(500).allow('')
});

// GET /api/bill-items - Get all bill-item relationships (org-scoped)
router.get('/', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const { bill_id, item_id, limit = 50, offset = 0 } = req.query;
    const filters = { branch_id: req.branchId, bill_id, item_id, limit, offset };
    const result = await BillItemService.getAllBillItems(filters);
    res.json(result);
  } catch (error) {
    console.error('Error fetching bill-items:', error);
    res.status(500).json({ error: 'Failed to fetch bill-items' });
  }
});

// GET /api/bill-items/stats/summary
router.get('/stats/summary', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const { bill_id, item_id } = req.query;
    const filters = { branch_id: req.branchId, bill_id, item_id };
    const stats = await BillItemService.getBillItemStats(filters);
    res.json(stats);
  } catch (error) {
    console.error('Error fetching bill-item stats:', error);
    res.status(500).json({ error: 'Failed to fetch bill-item statistics' });
  }
});

// GET /api/bill-items/bill/:bill_id - Get all items for a bill (before /:id)
router.get('/bill/:bill_id', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const result = await BillItemService.getItemsForBill(req.params.bill_id, req.branchId);
    res.json(result);
  } catch (error) {
    console.error('Error fetching items for bill:', error);
    if (error.message === 'Bill not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch items for bill' });
  }
});

// GET /api/bill-items/item/:item_id - Get all bills for an item (before /:id)
router.get('/item/:item_id', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const result = await BillItemService.getBillsForItem(req.params.item_id, req.branchId);
    res.json(result);
  } catch (error) {
    console.error('Error fetching bills for item:', error);
    if (error.message === 'Item not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch bills for item' });
  }
});

// GET /api/bill-items/:id
router.get('/:id', authenticateToken, validateBranch, requirePrivilege('bill', 'read'), async (req, res) => {
  try {
    const billItem = await BillItemService.getBillItemById(req.params.id, req.branchId);
    if (!billItem) return res.status(404).json({ error: 'Bill-item relationship not found' });
    res.json(billItem);
  } catch (error) {
    console.error('Error fetching bill-item:', error);
    res.status(500).json({ error: 'Failed to fetch bill-item' });
  }
});

// POST /api/bill-items - Add item to bill (requires bill.create so cajero can add lines when creating)
router.post('/', authenticateToken, validateBranch, requirePrivilege('bill', 'create'), async (req, res) => {
  try {
    const { error, value } = billItemSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const billItem = await BillItemService.addItemToBill(value, req.branchId);
    res.status(201).json(billItem);
  } catch (error) {
    console.error('Error creating bill-item:', error);
    if (error.message?.includes('not found') || error.message?.includes('does not belong')) {
      return res.status(404).json({ error: error.message });
    }
    if (error.message === 'Item is already associated with this bill') return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to create bill-item relationship' });
  }
});

// PUT /api/bill-items/:id
router.put('/:id', authenticateToken, validateBranch, requirePrivilege('bill', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = updateBillItemSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const billItem = await BillItemService.updateBillItem(id, req.branchId, value);
    res.json(billItem);
  } catch (error) {
    console.error('Error updating bill-item:', error);
    if (error.message === 'Bill-item relationship not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to update bill-item relationship' });
  }
});

// DELETE /api/bill-items/:id
router.delete('/:id', authenticateToken, validateBranch, requirePrivilege('bill', 'update'), async (req, res) => {
  try {
    const result = await BillItemService.removeItemFromBill(req.params.id, req.branchId);
    res.json(result);
  } catch (error) {
    console.error('Error deleting bill-item:', error);
    if (error.message === 'Bill-item relationship not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to remove item from bill' });
  }
});

module.exports = router;
