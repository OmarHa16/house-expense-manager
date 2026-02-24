const jwt = require('jsonwebtoken');
const { getQuery } = require('../database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Generate JWT token
function generateToken(user) {
  return jwt.sign(
    { userId: user.id, name: user.name, isAdmin: user.is_admin },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
}

// Verify JWT token middleware
async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Verify user still exists
    const user = await getQuery('SELECT id, name, is_admin FROM users WHERE id = ?', [decoded.userId]);
    
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    req.user = {
      userId: user.id,
      name: user.name,
      isAdmin: user.is_admin === 1
    };
    
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
}

// Admin-only middleware
function requireAdmin(req, res, next) {
  if (!req.user.isAdmin) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

module.exports = {
  generateToken,
  authenticateToken,
  requireAdmin,
  JWT_SECRET
};
