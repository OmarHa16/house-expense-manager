const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const bcrypt = require('bcryptjs');

const DB_PATH = path.join(__dirname, 'house_expense.db');

// Create database connection
const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('Error opening database:', err);
  } else {
    console.log('Connected to SQLite database');
    initializeDatabase();
  }
});

// Initialize database tables
function initializeDatabase() {
  db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      is_admin BOOLEAN DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Items table (master list)
    db.run(`CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      default_price REAL,
      category TEXT,
      is_deleted BOOLEAN DEFAULT 0,
      deleted_at DATETIME,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Invoices table
    db.run(`CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date DATETIME DEFAULT CURRENT_TIMESTAMP,
      created_by INTEGER NOT NULL,
      is_done BOOLEAN DEFAULT 0,
      total_amount REAL DEFAULT 0,
      is_deleted BOOLEAN DEFAULT 0,
      deleted_at DATETIME,
      FOREIGN KEY (created_by) REFERENCES users(id)
    )`);

    // Invoice items table
    db.run(`CREATE TABLE IF NOT EXISTS invoice_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL,
      item_id INTEGER,
      item_name TEXT,
      price_per_unit REAL NOT NULL,
      quantity REAL NOT NULL,
      consumers TEXT NOT NULL,
      is_deleted BOOLEAN DEFAULT 0,
      deleted_at DATETIME,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id),
      FOREIGN KEY (item_id) REFERENCES items(id)
    )`);

    // Payments table
    db.run(`CREATE TABLE IF NOT EXISTS payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      amount_paid REAL NOT NULL,
      is_deleted BOOLEAN DEFAULT 0,
      deleted_at DATETIME,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`);

    console.log('Database tables initialized');

    // Create default admin user (Omar)
    createDefaultAdmin();
  });
}

// Create default admin user
async function createDefaultAdmin() {
  const adminName = 'Omar';
  const adminPassword = 'admin123'; // Change this in production
  
  db.get('SELECT * FROM users WHERE name = ?', [adminName], async (err, row) => {
    if (err) {
      console.error('Error checking admin user:', err);
      return;
    }
    
    if (!row) {
      const hashedPassword = await bcrypt.hash(adminPassword, 10);
      db.run(
        'INSERT INTO users (name, password_hash, is_admin) VALUES (?, ?, ?)',
        [adminName, hashedPassword, 1],
        (err) => {
          if (err) {
            console.error('Error creating admin user:', err);
          } else {
            console.log('Default admin user created: Omar / admin123');
          }
        }
      );
    }
  });
}

// Helper function to run queries with promises
function runQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
}

function getQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

function allQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

module.exports = {
  db,
  runQuery,
  getQuery,
  allQuery
};
