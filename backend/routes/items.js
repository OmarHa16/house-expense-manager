const express = require('express');
const { runQuery, getQuery, allQuery } = require('../database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/items - List all items (excluding soft-deleted)
router.get('/', authenticateToken, async (req, res) => {
  try {
    const items = await allQuery(
      `SELECT id, name, default_price, category, created_at 
       FROM items 
       WHERE is_deleted = 0 OR is_deleted IS NULL 
       ORDER BY name`
    );
    res.json(items);
  } catch (error) {
    console.error('Error fetching items:', error);
    res.status(500).json({ error: 'Failed to fetch items' });
  }
});

// POST /api/items - Create new item
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { name, defaultPrice, category } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Item name is required' });
    }

    // Check if item exists (including deleted ones)
    const existingItem = await getQuery('SELECT id, is_deleted FROM items WHERE name = ?', [name]);
    
    if (existingItem) {
      if (existingItem.is_deleted === 1) {
        // Restore the deleted item
        await runQuery(
          'UPDATE items SET is_deleted = 0, deleted_at = NULL, default_price = ?, category = ? WHERE id = ?',
          [defaultPrice || null, category || null, existingItem.id]
        );
        
        const restoredItem = await getQuery(
          'SELECT id, name, default_price, category, created_at FROM items WHERE id = ?',
          [existingItem.id]
        );
        return res.status(200).json({ ...restoredItem, restored: true });
      }
      return res.status(409).json({ error: 'Item already exists' });
    }

    const result = await runQuery(
      'INSERT INTO items (name, default_price, category) VALUES (?, ?, ?)',
      [name, defaultPrice || null, category || null]
    );

    const newItem = await getQuery(
      'SELECT id, name, default_price, category, created_at FROM items WHERE id = ?',
      [result.id]
    );

    res.status(201).json(newItem);
  } catch (error) {
    console.error('Error creating item:', error);
    res.status(500).json({ error: 'Failed to create item' });
  }
});

// PUT /api/items/:id - Update item
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const itemId = req.params.id;
    const { name, defaultPrice, category } = req.body;

    const item = await getQuery('SELECT id FROM items WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)', [itemId]);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    await runQuery(
      'UPDATE items SET name = ?, default_price = ?, category = ? WHERE id = ?',
      [name, defaultPrice || null, category || null, itemId]
    );

    const updatedItem = await getQuery(
      'SELECT id, name, default_price, category, created_at FROM items WHERE id = ?',
      [itemId]
    );

    res.json(updatedItem);
  } catch (error) {
    console.error('Error updating item:', error);
    res.status(500).json({ error: 'Failed to update item' });
  }
});

// DELETE /api/items/:id - Soft delete item (admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    if (!req.user.isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }

    const itemId = req.params.id;

    const item = await getQuery('SELECT id FROM items WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)', [itemId]);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    await runQuery(
      'UPDATE items SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
      [itemId]
    );

    res.json({ 
      message: 'Item deleted successfully',
      undoAvailable: true,
      undoExpiresAt: new Date(Date.now() + 10000).toISOString()
    });
  } catch (error) {
    console.error('Error deleting item:', error);
    res.status(500).json({ error: 'Failed to delete item' });
  }
});

// POST /api/items/:id/undo - Undo soft delete (admin only, within 10 seconds)
router.post('/:id/undo', authenticateToken, async (req, res) => {
  try {
    if (!req.user.isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }

    const itemId = req.params.id;

    const item = await getQuery(
      'SELECT id, deleted_at FROM items WHERE id = ? AND is_deleted = 1',
      [itemId]
    );

    if (!item) {
      return res.status(404).json({ error: 'Deleted item not found' });
    }

    // Check if within 10 second window
    const deletedAt = new Date(item.deleted_at);
    const now = new Date();
    if (now - deletedAt > 10000) {
      return res.status(410).json({ error: 'Undo period has expired' });
    }

    await runQuery(
      'UPDATE items SET is_deleted = 0, deleted_at = NULL WHERE id = ?',
      [itemId]
    );

    const restoredItem = await getQuery(
      'SELECT id, name, default_price, category, created_at FROM items WHERE id = ?',
      [itemId]
    );

    res.json({ message: 'Item restored successfully', item: restoredItem });
  } catch (error) {
    console.error('Error undoing delete:', error);
    res.status(500).json({ error: 'Failed to restore item' });
  }
});

module.exports = router;
