const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const itemRoutes = require('./routes/items');
const invoiceRoutes = require('./routes/invoices');
const balanceRoutes = require('./routes/balances');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/items', itemRoutes);
app.use('/api/invoices', invoiceRoutes);
app.use('/api/balances', balanceRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Serve Flutter Web App static files with cache-busting
const flutterWebPath = path.join(__dirname, 'public');
app.use(express.static(flutterWebPath, {
  setHeaders: (res, path) => {
    // Disable caching for HTML and JS files to ensure updates are loaded
    if (path.endsWith('.html') || path.endsWith('.js')) {
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
    }
  }
}));

// Handle all routes by serving index.html (for Flutter routing)
app.get('*', (req, res) => {
  // Don't serve index.html for API routes
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ error: 'Endpoint not found' });
  }
  res.sendFile(path.join(flutterWebPath, 'index.html'));
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 API: http://localhost:${PORT}/api`);
  console.log(`🌐 Web App: http://localhost:${PORT}`);
  console.log('');
  console.log(`Network access:`);
  console.log(`  http://192.168.0.214:${PORT}`);
  console.log(`  http://192.168.126.1:${PORT}`);
  console.log(`  http://192.168.74.1:${PORT}`);
  console.log('');
  console.log('Default login: Omar / admin123');
});
