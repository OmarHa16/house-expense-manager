const express = require('express');
const { allQuery, getQuery } = require('../database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/balances - Get all users' balances
router.get('/', authenticateToken, async (req, res) => {
  try {
    const balances = await calculateBalances();
    res.json(balances);
  } catch (error) {
    console.error('Error calculating balances:', error);
    res.status(500).json({ error: 'Failed to calculate balances' });
  }
});

// GET /api/balances/me - Get current user's balance details
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const allBalances = await calculateBalances();
    const userBalance = allBalances.find(b => b.userId === userId);
    
    if (!userBalance) {
      return res.status(404).json({ error: 'User balance not found' });
    }

    // Calculate who owes whom
    const transactions = calculateTransactions(allBalances);

    res.json({
      ...userBalance,
      owesTo: transactions.filter(t => t.from === userId),
      owedFrom: transactions.filter(t => t.to === userId)
    });
  } catch (error) {
    console.error('Error calculating user balance:', error);
    res.status(500).json({ error: 'Failed to calculate balance' });
  }
});

// Helper function to calculate all balances
async function calculateBalances() {
  // Get all users
  const users = await allQuery('SELECT id, name FROM users ORDER BY name');
  
  // Get all active invoices with items and payments
  const invoices = await allQuery(`
    SELECT i.id, i.total_amount
    FROM invoices i
    WHERE (i.is_deleted = 0 OR i.is_deleted IS NULL) AND i.is_done = 0
  `);

  const balances = {};

  // Initialize balances for all users
  for (const user of users) {
    balances[user.id] = {
      userId: user.id,
      name: user.name,
      amountOwed: 0,
      amountPaid: 0,
      netBalance: 0
    };
  }

  // Process each invoice
  for (const invoice of invoices) {
    // Get items for this invoice
    const items = await allQuery(`
      SELECT ii.price_per_unit, ii.quantity, ii.consumers
      FROM invoice_items ii
      WHERE ii.invoice_id = ? AND (ii.is_deleted = 0 OR ii.is_deleted IS NULL)
    `, [invoice.id]);

    // Calculate what each user owes for items
    for (const item of items) {
      const consumers = JSON.parse(item.consumers);
      const totalItemCost = item.price_per_unit * item.quantity;
      const costPerConsumer = totalItemCost / consumers.length;

      for (const consumerId of consumers) {
        if (balances[consumerId]) {
          balances[consumerId].amountOwed += costPerConsumer;
        }
      }
    }

    // Get payments for this invoice
    const payments = await allQuery(`
      SELECT p.user_id, p.amount_paid
      FROM payments p
      WHERE p.invoice_id = ? AND (p.is_deleted = 0 OR p.is_deleted IS NULL)
    `, [invoice.id]);

    // Add payments
    for (const payment of payments) {
      if (balances[payment.user_id]) {
        balances[payment.user_id].amountPaid += payment.amount_paid;
      }
    }
  }

  // Calculate net balance for each user
  for (const userId in balances) {
    const balance = balances[userId];
    balance.netBalance = balance.amountPaid - balance.amountOwed;
  }

  return Object.values(balances);
}

// Helper function to calculate who owes whom
function calculateTransactions(balances) {
  const transactions = [];
  
  // Separate debtors (negative balance) and creditors (positive balance)
  const debtors = balances.filter(b => b.netBalance < 0).map(b => ({
    ...b,
    amount: Math.abs(b.netBalance)
  }));
  
  const creditors = balances.filter(b => b.netBalance > 0).map(b => ({
    ...b,
    amount: b.netBalance
  }));

  // Match debtors with creditors
  for (const debtor of debtors) {
    let remainingDebt = debtor.amount;
    
    for (const creditor of creditors) {
      if (remainingDebt <= 0) break;
      if (creditor.amount <= 0) continue;
      
      const transferAmount = Math.min(remainingDebt, creditor.amount);
      
      if (transferAmount > 0.01) { // Only record significant amounts
        transactions.push({
          from: debtor.userId,
          fromName: debtor.name,
          to: creditor.userId,
          toName: creditor.name,
          amount: Math.round(transferAmount * 100) / 100
        });
        
        remainingDebt -= transferAmount;
        creditor.amount -= transferAmount;
      }
    }
  }

  return transactions;
}

// GET /api/balances/summary - Get summary of all debts
router.get('/summary', authenticateToken, async (req, res) => {
  try {
    const balances = await calculateBalances();
    const transactions = calculateTransactions(balances);
    
    const totalOwed = balances.reduce((sum, b) => sum + Math.max(0, -b.netBalance), 0);
    const totalPaid = balances.reduce((sum, b) => sum + Math.max(0, b.netBalance), 0);

    res.json({
      totalActiveDebt: Math.round(totalOwed * 100) / 100,
      totalToBeReceived: Math.round(totalPaid * 100) / 100,
      userCount: balances.length,
      activeTransactions: transactions.length,
      transactions: transactions
    });
  } catch (error) {
    console.error('Error calculating summary:', error);
    res.status(500).json({ error: 'Failed to calculate summary' });
  }
});

module.exports = router;
