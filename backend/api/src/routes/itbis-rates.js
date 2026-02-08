const express = require('express');
const router = express.Router();
const { ItbisRateService } = require('../services');
const { authenticateToken } = require('../middleware/auth');
const { validateOrganization } = require('../middleware/organization');

// GET /api/itbis-rates - List all ITBIS rates (for product forms)
router.get('/', authenticateToken, validateOrganization, async (req, res) => {
  try {
    const rates = await ItbisRateService.getAll();
    res.json({ itbis_rates: rates });
  } catch (error) {
    console.error('Error fetching ITBIS rates:', error);
    res.status(500).json({ error: 'Failed to fetch ITBIS rates' });
  }
});

// GET /api/itbis-rates/:id - Get one ITBIS rate
router.get('/:id', authenticateToken, validateOrganization, async (req, res) => {
  try {
    const rate = await ItbisRateService.getById(req.params.id);
    if (!rate) return res.status(404).json({ error: 'ITBIS rate not found' });
    res.json(rate);
  } catch (error) {
    console.error('Error fetching ITBIS rate:', error);
    res.status(500).json({ error: 'Failed to fetch ITBIS rate' });
  }
});

module.exports = router;
