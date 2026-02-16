const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { ItemService, ItemCategoryService } = require('../services');
const { authenticateToken, requirePrivilege } = require('../middleware/auth');
const { validateBranch } = require('../middleware/branch');

const itemSchema = Joi.object({
  name: Joi.string().min(1).max(100).required(),
  description: Joi.string().max(500).allow(''),
  unit_price: Joi.number().positive().precision(2).required(),
  category_id: Joi.number().integer().positive().allow(null),
  itbis_rate_id: Joi.number().integer().positive().required()
});

const updateItemSchema = Joi.object({
  name: Joi.string().min(1).max(100),
  description: Joi.string().max(500).allow(''),
  unit_price: Joi.number().positive().precision(2),
  category_id: Joi.number().integer().positive().allow(null),
  itbis_rate_id: Joi.number().integer().positive()
});

// GET /api/items - Get all items (branch-scoped)
router.get('/', authenticateToken, validateBranch, requirePrivilege('item', 'read'), async (req, res) => {
  try {
    const { category, search, limit = 50, offset = 0 } = req.query;
    const filters = { branch_id: req.branchId, search, limit, offset };
    if (category) filters.category = category;
    const result = await ItemService.getAllItems(filters);
    res.json(result);
  } catch (error) {
    console.error('Error fetching items:', error);
    res.status(500).json({ error: 'Failed to fetch items' });
  }
});

// GET /api/items/categories - Get all item categories (must be before /:id)
router.get('/categories', authenticateToken, validateBranch, requirePrivilege('item', 'read'), async (req, res) => {
  try {
    const { limit = 50, offset = 0, includeItemCount = true } = req.query;
    const result = await ItemCategoryService.getAllCategories({
      branch_id: req.branchId,
      limit,
      offset,
      includeItemCount: includeItemCount === 'true'
    });
    res.json(result);
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// POST /api/items/categories - Create a new category
router.post('/categories', authenticateToken, validateBranch, requirePrivilege('item', 'create'), async (req, res) => {
  try {
    const categorySchema = Joi.object({
      name: Joi.string().min(1).max(50).required(),
      description: Joi.string().max(500).allow('')
    });
    const { error, value } = categorySchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    value.branch_id = req.branchId;
    const category = await ItemCategoryService.createCategory(value);
    res.status(201).json(category);
  } catch (error) {
    console.error('Error creating category:', error);
    if (error.message?.includes('already exists')) return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to create category' });
  }
});

// GET /api/items/categories/:id - Get specific category
router.get('/categories/:id', authenticateToken, validateBranch, requirePrivilege('item', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const { includeItems = false } = req.query;
    const category = await ItemCategoryService.getCategoryById(id, req.branchId, includeItems === 'true');
    if (!category) return res.status(404).json({ error: 'Category not found' });
    res.json(category);
  } catch (error) {
    console.error('Error fetching category:', error);
    res.status(500).json({ error: 'Failed to fetch category' });
  }
});

// PUT /api/items/categories/:id - Update category
router.put('/categories/:id', authenticateToken, validateBranch, requirePrivilege('item', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const categorySchema = Joi.object({
      name: Joi.string().min(1).max(50),
      description: Joi.string().max(500).allow('')
    });
    const { error, value } = categorySchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const category = await ItemCategoryService.updateCategory(id, req.branchId, value);
    res.json(category);
  } catch (error) {
    console.error('Error updating category:', error);
    if (error.message === 'Category not found') return res.status(404).json({ error: error.message });
    if (error.message?.includes('already exists')) return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to update category' });
  }
});

// DELETE /api/items/categories/:id - Delete category
router.delete('/categories/:id', authenticateToken, validateBranch, requirePrivilege('item', 'delete'), async (req, res) => {
  try {
    const { id } = req.params;
    const result = await ItemCategoryService.deleteCategory(id, req.branchId);
    res.json({ message: 'Category deleted successfully', category: result });
  } catch (error) {
    console.error('Error deleting category:', error);
    if (error.message === 'Category not found') return res.status(404).json({ error: error.message });
    if (error.message?.includes('being used')) return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to delete category' });
  }
});

// GET /api/items/categories/:id/stats - Get category statistics
router.get('/categories/:id/stats', authenticateToken, validateBranch, requirePrivilege('item', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const stats = await ItemCategoryService.getCategoryStats(id, req.branchId);
    res.json(stats);
  } catch (error) {
    console.error('Error fetching category stats:', error);
    if (error.message === 'Category not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch category statistics' });
  }
});

// GET /api/items/:id - Get a specific item
router.get('/:id', authenticateToken, validateBranch, requirePrivilege('item', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const item = await ItemService.getItemById(id, req.branchId);
    if (!item) return res.status(404).json({ error: 'Item not found' });
    res.json(item);
  } catch (error) {
    console.error('Error fetching item:', error);
    res.status(500).json({ error: 'Failed to fetch item' });
  }
});

// POST /api/items - Create a new item
router.post('/', authenticateToken, validateBranch, requirePrivilege('item', 'create'), async (req, res) => {
  try {
    const { error, value } = itemSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    value.branch_id = req.branchId;
    const item = await ItemService.createItem(value);
    res.status(201).json(item);
  } catch (error) {
    console.error('Error creating item:', error);
    if (error.message?.includes('already exists') || error.message === 'Category not found') {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to create item' });
  }
});

// PUT /api/items/:id - Update an item
router.put('/:id', authenticateToken, validateBranch, requirePrivilege('item', 'update'), async (req, res) => {
  try {
    const { id } = req.params;
    const { error, value } = updateItemSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: 'Validation error', details: error.details.map(d => d.message) });
    }
    const item = await ItemService.updateItem(id, req.branchId, value);
    res.json(item);
  } catch (error) {
    console.error('Error updating item:', error);
    if (error.message === 'Item not found' || error.message === 'Category not found') {
      return res.status(404).json({ error: error.message });
    }
    if (error.message?.includes('already exists')) return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to update item' });
  }
});

// DELETE /api/items/:id - Delete an item
router.delete('/:id', authenticateToken, validateBranch, requirePrivilege('item', 'delete'), async (req, res) => {
  try {
    const { id } = req.params;
    const result = await ItemService.deleteItem(id, req.branchId);
    res.json({ message: 'Item deleted successfully', item: result });
  } catch (error) {
    console.error('Error deleting item:', error);
    if (error.message === 'Item not found') return res.status(404).json({ error: error.message });
    if (error.message?.includes('being used')) return res.status(400).json({ error: error.message });
    res.status(500).json({ error: 'Failed to delete item' });
  }
});

// GET /api/items/:id/stats - Get item usage statistics
router.get('/:id/stats', authenticateToken, validateBranch, requirePrivilege('item', 'read'), async (req, res) => {
  try {
    const { id } = req.params;
    const stats = await ItemService.getItemStats(id, req.branchId);
    res.json(stats);
  } catch (error) {
    console.error('Error fetching item stats:', error);
    if (error.message === 'Item not found') return res.status(404).json({ error: error.message });
    res.status(500).json({ error: 'Failed to fetch item statistics' });
  }
});

module.exports = router;
