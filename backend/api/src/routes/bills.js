const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { BillService } = require('../services');
const { authenticateToken } = require('../middleware/auth');

// Validation schemas
const billSchema = Joi.object({
  title: Joi.string().min(1).max(100).required(),
  description: Joi.string().max(500).allow(''),
  amount: Joi.number().positive().precision(2).required()
});

const updateBillSchema = Joi.object({
  title: Joi.string().min(1).max(100),
  description: Joi.string().max(500).allow(''),
  amount: Joi.number().positive().precision(2)
});

// GET /api/bills - Get all bills with optional filtering
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;

    const filters = {
      user_id: req.userId,
      limit,
      offset
    };
    const result = await BillService.getAllBills(filters);

    res.json(result);
  } catch (error) {
    console.error('Error fetching bills:', error);
    res.status(500).json({ error: 'Failed to fetch bills' });
  }
});

// GET /api/bills/stats/summary - Get bills summary (must be before /:id)
router.get('/stats/summary', authenticateToken, async (req, res) => {
  try {
    const stats = await BillService.getBillStats(req.userId);
    res.json(stats);
  } catch (error) {
    console.error('Error fetching bill stats:', error);
    res.status(500).json({ error: 'Failed to fetch bill statistics' });
  }
});

// GET /api/bills/:id - Get a specific bill
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const bill = await BillService.getBillById(id, req.userId);

    if (!bill) {
      return res.status(404).json({ error: 'Bill not found' });
    }

    res.json(bill);
  } catch (error) {
    console.error('Error fetching bill:', error);
    res.status(500).json({ error: 'Failed to fetch bill' });
  }
});

// POST /api/bills - Create a new bill
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { error, value } = billSchema.validate(req.body);

    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    value.user_id = req.userId;

    const bill = await BillService.createBill(value);
    res.status(201).json(bill);
  } catch (error) {
    console.error('Error creating bill:', error);
    if (error.message === 'User not found') {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to create bill' });
  }
});

// PUT /api/bills/:id - Update a bill
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = updateBillSchema.validate(req.body);

    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details.map(d => d.message)
      });
    }

    const bill = await BillService.updateBill(id, req.userId, value);
    res.json(bill);
  } catch (error) {
    console.error('Error updating bill:', error);
    if (error.message === 'Bill not found') {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to update bill' });
  }
});

// DELETE /api/bills/:id - Delete a bill
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await BillService.deleteBill(id, req.userId);
    res.json(result);
  } catch (error) {
    console.error('Error deleting bill:', error);
    if (error.message === 'Bill not found') {
      return res.status(404).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to delete bill' });
  }
});

module.exports = router;
