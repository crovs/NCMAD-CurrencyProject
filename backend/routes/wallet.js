const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { walletQueries, transactionQueries, db } = require('../database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Currency names mapping
const currencyNames = {
    PLN: 'Polish Zloty',
    USD: 'US Dollar',
    EUR: 'Euro',
    GBP: 'British Pound',
    CHF: 'Swiss Franc',
    JPY: 'Japanese Yen'
};

// Get all wallets for user
router.get('/:userId', authenticateToken, (req, res) => {
    try {
        const { userId } = req.params;

        // Verify user is requesting their own wallets
        if (req.user.userId !== userId) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        const wallets = walletQueries.findAllByUser.all(userId);
        res.json(wallets);
    } catch (error) {
        console.error('Get wallets error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Fund account (add money to wallet)
router.post('/fund', authenticateToken, (req, res) => {
    try {
        const { userId, amount, currency = 'PLN' } = req.body;

        // Verify user is funding their own account
        if (req.user.userId !== userId) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        // Validation
        if (!amount || amount <= 0) {
            return res.status(400).json({ error: 'Invalid amount' });
        }

        // Use transaction for atomicity
        const result = db.transaction(() => {
            // Check if wallet exists
            let wallet = walletQueries.findByUserAndCurrency.get(userId, currency);

            if (wallet) {
                // Update existing wallet
                walletQueries.incrementBalance.run(amount, userId, currency);
            } else {
                // Create new wallet
                const walletId = uuidv4();
                walletQueries.create.run(
                    walletId,
                    userId,
                    currency,
                    currencyNames[currency] || currency,
                    amount
                );
            }

            // Create fund transaction record
            const transactionId = uuidv4();
            transactionQueries.create.run(
                transactionId,
                userId,
                'SYSTEM',
                currency,
                amount,
                amount,
                1.0,
                'fund'
            );

            return { success: true };
        })();

        res.json({ message: 'Account funded successfully', ...result });
    } catch (error) {
        console.error('Fund account error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get specific wallet balance
router.get('/:userId/:currency', authenticateToken, (req, res) => {
    try {
        const { userId, currency } = req.params;

        // Verify user is requesting their own wallet
        if (req.user.userId !== userId) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        const wallet = walletQueries.findByUserAndCurrency.get(userId, currency);

        if (!wallet) {
            return res.json({ balance: 0, currency });
        }

        res.json(wallet);
    } catch (error) {
        console.error('Get wallet error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
