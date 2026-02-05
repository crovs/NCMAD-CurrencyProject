const express = require('express');
const { userQueries, walletQueries, transactionQueries, db } = require('../database');

const router = express.Router();

// Database viewer endpoint (for demonstration)
router.get('/database', (req, res) => {
    try {
        // Get all users (without passwords)
        const users = db.prepare(`
            SELECT id, email, name, created_at 
            FROM users 
            ORDER BY created_at DESC
        `).all();

        // Get all wallets with user emails
        const wallets = db.prepare(`
            SELECT 
                w.*,
                u.email as user_email
            FROM currency_wallets w
            JOIN users u ON w.user_id = u.id
            ORDER BY w.updated_at DESC
        `).all();

        // Get all transactions with user emails
        const transactions = db.prepare(`
            SELECT 
                t.id,
                t.user_id,
                t.from_currency,
                t.to_currency,
                t.from_amount,
                t.to_amount,
                t.exchange_rate,
                t.transaction_type as type,
                t.timestamp,
                u.email as user_email
            FROM transactions t
            JOIN users u ON t.user_id = u.id
            ORDER BY t.timestamp DESC
            LIMIT 100
        `).all();

        // Calculate total PLN balance
        const totalBalance = wallets
            .filter(w => w.currency_code === 'PLN')
            .reduce((sum, w) => sum + w.balance, 0);

        console.log('✅ Database query successful:');
        console.log(`   Users: ${users.length}`);
        console.log(`   Wallets: ${wallets.length}`);
        console.log(`   Transactions: ${transactions.length}`);

        res.json({
            users,
            wallets,
            transactions,
            totalBalance: totalBalance.toFixed(2),
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Database viewer error:', error);
        res.status(500).json({ error: 'Failed to fetch database data' });
    }
});

module.exports = router;
