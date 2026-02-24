const express = require('express');
const { runQuery, getQuery, allQuery, db } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/invoices - List all invoices
router.get('/', authenticateToken, async (req, res) => {
  try {
    const invoices = await allQuery(`
      SELECT 
        i.id,
        i.date,
        i.created_by,
        u.name as created_by_name,
        i.is_done,
        i.total_amount,
        i.is_deleted
      FROM invoices i
      LEFT JOIN users u ON i.created_by = u.id
      WHERE i.is_deleted = 0 OR i.is_deleted IS NULL
      ORDER BY i.date DESC
    `);

    // Get items and payments for each invoice
    for (let invoice of invoices) {
      invoice.items = await allQuery(`
        SELECT 
          ii.id,
          ii.item_id,
          COALESCE(it.name, ii.item_name) as item_name,
          ii.price_per_unit,
          ii.quantity,
          ii.consumers,
          (ii.price_per_unit * ii.quantity) as total_price
        FROM invoice_items ii
        LEFT JOIN items it ON ii.item_id = it.id
        WHERE ii.invoice_id = ? AND (ii.is_deleted = 0 OR ii.is_deleted IS NULL)
      `, [invoice.id]);

      invoice.payments = await allQuery(`
        SELECT 
          p.id,
          p.user_id,
          u.name as user_name,
          p.amount_paid
        FROM payments p
        LEFT JOIN users u ON p.user_id = u.id
        WHERE p.invoice_id = ? AND (p.is_deleted = 0 OR p.is_deleted IS NULL)
      `, [invoice.id]);
    }

    res.json(invoices);
  } catch (error) {
    console.error('Error fetching invoices:', error);
    res.status(500).json({ error: 'Failed to fetch invoices' });
  }
});

// GET /api/invoices/:id - Get single invoice details
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const invoiceId = req.params.id;

    const invoice = await getQuery(`
      SELECT 
        i.id,
        i.date,
        i.created_by,
        u.name as created_by_name,
        i.is_done,
        i.total_amount,
        i.is_deleted
      FROM invoices i
      LEFT JOIN users u ON i.created_by = u.id
      WHERE i.id = ? AND (i.is_deleted = 0 OR i.is_deleted IS NULL)
    `, [invoiceId]);

    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }

    invoice.items = await allQuery(`
      SELECT 
        ii.id,
        ii.item_id,
        COALESCE(it.name, ii.item_name) as item_name,
        ii.price_per_unit,
        ii.quantity,
        ii.consumers,
        (ii.price_per_unit * ii.quantity) as total_price
      FROM invoice_items ii
      LEFT JOIN items it ON ii.item_id = it.id
      WHERE ii.invoice_id = ? AND (ii.is_deleted = 0 OR ii.is_deleted IS NULL)
    `, [invoiceId]);

    invoice.payments = await allQuery(`
      SELECT 
        p.id,
        p.user_id,
        u.name as user_name,
        p.amount_paid
      FROM payments p
      LEFT JOIN users u ON p.user_id = u.id
      WHERE p.invoice_id = ? AND (p.is_deleted = 0 OR p.is_deleted IS NULL)
    `, [invoiceId]);

    res.json(invoice);
  } catch (error) {
    console.error('Error fetching invoice:', error);
    res.status(500).json({ error: 'Failed to fetch invoice' });
  }
});

// POST /api/invoices - Create new invoice
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { items, payments } = req.body;
    const createdBy = req.user.userId;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'At least one item is required' });
    }

    // Calculate total amount
    let totalAmount = 0;
    for (const item of items) {
      const itemTotal = item.pricePerUnit * item.quantity;
      totalAmount += itemTotal;
    }

    // Validate payments total matches invoice total
    const paymentsTotal = payments.reduce((sum, p) => sum + p.amountPaid, 0);
    if (Math.abs(paymentsTotal - totalAmount) > 0.01) {
      return res.status(400).json({ 
        error: 'Payments total must match invoice total',
        invoiceTotal: totalAmount,
        paymentsTotal: paymentsTotal
      });
    }

    // Start transaction
    await runQuery('BEGIN TRANSACTION');

    try {
      // Create invoice
      const invoiceResult = await runQuery(
        'INSERT INTO invoices (created_by, total_amount) VALUES (?, ?)',
        [createdBy, totalAmount]
      );
      const invoiceId = invoiceResult.id;

      // Add invoice items
      for (const item of items) {
        // Handle new items
        let itemId = item.itemId;
        if (!itemId && item.itemName) {
          // Check if item exists
          const existingItem = await getQuery('SELECT id FROM items WHERE name = ?', [item.itemName]);
          if (existingItem) {
            itemId = existingItem.id;
          } else {
            // Create new item
            const newItemResult = await runQuery(
              'INSERT INTO items (name, default_price) VALUES (?, ?)',
              [item.itemName, item.pricePerUnit]
            );
            itemId = newItemResult.id;
          }
        }

        await runQuery(
          `INSERT INTO invoice_items 
           (invoice_id, item_id, item_name, price_per_unit, quantity, consumers) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [
            invoiceId,
            itemId,
            item.itemName || null,
            item.pricePerUnit,
            item.quantity,
            JSON.stringify(item.consumers)
          ]
        );
      }

      // Add payments
      for (const payment of payments) {
        await runQuery(
          'INSERT INTO payments (invoice_id, user_id, amount_paid) VALUES (?, ?, ?)',
          [invoiceId, payment.userId, payment.amountPaid]
        );
      }

      await runQuery('COMMIT');

      // Fetch and return the created invoice
      const newInvoice = await getQuery(`
        SELECT 
          i.id,
          i.date,
          i.created_by,
          u.name as created_by_name,
          i.is_done,
          i.total_amount
        FROM invoices i
        LEFT JOIN users u ON i.created_by = u.id
        WHERE i.id = ?
      `, [invoiceId]);

      newInvoice.items = await allQuery(`
        SELECT 
          ii.id,
          ii.item_id,
          COALESCE(it.name, ii.item_name) as item_name,
          ii.price_per_unit,
          ii.quantity,
          ii.consumers,
          (ii.price_per_unit * ii.quantity) as total_price
        FROM invoice_items ii
        LEFT JOIN items it ON ii.item_id = it.id
        WHERE ii.invoice_id = ?
      `, [invoiceId]);

      newInvoice.payments = await allQuery(`
        SELECT 
          p.id,
          p.user_id,
          u.name as user_name,
          p.amount_paid
        FROM payments p
        LEFT JOIN users u ON p.user_id = u.id
        WHERE p.invoice_id = ?
      `, [invoiceId]);

      res.status(201).json(newInvoice);
    } catch (error) {
      await runQuery('ROLLBACK');
      throw error;
    }
  } catch (error) {
    console.error('Error creating invoice:', error);
    res.status(500).json({ error: 'Failed to create invoice' });
  }
});

// PUT /api/invoices/:id/done - Mark invoice as done (any authenticated user)
router.put('/:id/done', authenticateToken, async (req, res) => {
  try {
    const invoiceId = req.params.id;

    const invoice = await getQuery(
      'SELECT id FROM invoices WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
      [invoiceId]
    );

    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }

    await runQuery(
      'UPDATE invoices SET is_done = 1 WHERE id = ?',
      [invoiceId]
    );

    res.json({ message: 'Invoice marked as done' });
  } catch (error) {
    console.error('Error marking invoice done:', error);
    res.status(500).json({ error: 'Failed to mark invoice as done' });
  }
});

// DELETE /api/invoices/:id - Soft delete invoice (admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    if (!req.user.isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }

    const invoiceId = req.params.id;

    const invoice = await getQuery(
      'SELECT id FROM invoices WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
      [invoiceId]
    );

    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }

    await runQuery(
      'UPDATE invoices SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
      [invoiceId]
    );

    // Also soft delete related items and payments
    await runQuery(
      'UPDATE invoice_items SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP WHERE invoice_id = ?',
      [invoiceId]
    );

    await runQuery(
      'UPDATE payments SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP WHERE invoice_id = ?',
      [invoiceId]
    );

    res.json({ 
      message: 'Invoice deleted successfully',
      undoAvailable: true,
      undoExpiresAt: new Date(Date.now() + 10000).toISOString()
    });
  } catch (error) {
    console.error('Error deleting invoice:', error);
    res.status(500).json({ error: 'Failed to delete invoice' });
  }
});

// POST /api/invoices/:id/undo - Undo soft delete (admin only, within 10 seconds)
router.post('/:id/undo', authenticateToken, async (req, res) => {
  try {
    if (!req.user.isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }

    const invoiceId = req.params.id;

    const invoice = await getQuery(
      'SELECT id, deleted_at FROM invoices WHERE id = ? AND is_deleted = 1',
      [invoiceId]
    );

    if (!invoice) {
      return res.status(404).json({ error: 'Deleted invoice not found' });
    }

    // Check if within 10 second window (with small buffer for network latency)
    // SQLite stores in UTC, so we need to compare properly
    const deletedAt = new Date(invoice.deleted_at + 'Z'); // Force UTC interpretation
    const now = new Date();
    const elapsed = now.getTime() - deletedAt.getTime();
    if (elapsed > 11000) {
      return res.status(410).json({ error: 'Undo period has expired' });
    }

    await runQuery(
      'UPDATE invoices SET is_deleted = 0, deleted_at = NULL WHERE id = ?',
      [invoiceId]
    );

    // Restore related items and payments
    await runQuery(
      'UPDATE invoice_items SET is_deleted = 0, deleted_at = NULL WHERE invoice_id = ?',
      [invoiceId]
    );

    await runQuery(
      'UPDATE payments SET is_deleted = 0, deleted_at = NULL WHERE invoice_id = ?',
      [invoiceId]
    );

    res.json({ message: 'Invoice restored successfully' });
  } catch (error) {
    console.error('Error undoing delete:', error);
    res.status(500).json({ error: 'Failed to restore invoice' });
  }
});

module.exports = router;
