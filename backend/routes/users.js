const express = require('express');
const bcrypt = require('bcryptjs');
const { runQuery, getQuery, allQuery } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/users - List all users (admin only)
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await allQuery(
      'SELECT id, name, is_admin, created_at FROM users ORDER BY name'
    );
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// POST /api/users - Create new user (admin only)
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { name, password, isAdmin = false } = req.body;

    if (!name || !password) {
      return res.status(400).json({ error: 'Name and password are required' });
    }

    // Check if user exists
    const existingUser = await getQuery('SELECT id FROM users WHERE name = ?', [name]);
    if (existingUser) {
      return res.status(409).json({ error: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    
    const result = await runQuery(
      'INSERT INTO users (name, password_hash, is_admin) VALUES (?, ?, ?)',
      [name, hashedPassword, isAdmin ? 1 : 0]
    );

    const newUser = await getQuery(
      'SELECT id, name, is_admin, created_at FROM users WHERE id = ?',
      [result.id]
    );

    res.status(201).json(newUser);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// POST /api/users/:id/change-password - Admin change user password (admin only)
router.post('/:id/change-password', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const userId = req.params.id;
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 4) {
      return res.status(400).json({ error: 'New password must be at least 4 characters' });
    }

    // Check if user exists
    const user = await getQuery('SELECT id FROM users WHERE id = ?', [userId]);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    await runQuery(
      'UPDATE users SET password_hash = ? WHERE id = ?',
      [hashedPassword, userId]
    );

    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ error: 'Failed to change password' });
  }
});

// PUT /api/users/:id/promote - Promote user to admin (admin only)
router.put('/:id/promote', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Check if user exists
    const user = await getQuery('SELECT id, is_admin FROM users WHERE id = ?', [userId]);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.is_admin === 1) {
      return res.status(400).json({ error: 'User is already an admin' });
    }

    await runQuery(
      'UPDATE users SET is_admin = 1 WHERE id = ?',
      [userId]
    );

    res.json({ message: 'User promoted to admin successfully' });
  } catch (error) {
    console.error('Error promoting user:', error);
    res.status(500).json({ error: 'Failed to promote user' });
  }
});

// DELETE /api/users/:id - Delete user (admin only)
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Prevent self-deletion
    if (parseInt(userId) === req.user.userId) {
      return res.status(400).json({ error: 'Cannot delete yourself' });
    }

    const user = await getQuery('SELECT id FROM users WHERE id = ?', [userId]);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    await runQuery('DELETE FROM users WHERE id = ?', [userId]);
    
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

module.exports = router;
