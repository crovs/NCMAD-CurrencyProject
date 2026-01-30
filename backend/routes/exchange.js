const express = require('express');
const { v4: uuidv4 } = require('uuid');
const fetch = require('node-fetch');
const { walletQueries, transactionQueries, db } = require('../database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

const NBP_API_BASE = 'https://api.nbp.pl/api';

// Get current exchange rates (proxy NBP API)
router.get('/rates', async (req, res) => {
    try {
        const response = await fetch(`${NBP_API_BASE}/exchangerates/tables/A/?format=json`);

        if (!response.ok) {
            throw new Error('Failed to fetch rates from NBP');
        }

        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('Get rates error:', error);
        res.status(500).json({ error: 'Failed to fetch exchange rates' });
    }
});

// Execute currency exchange
router.post('/', authenticateToken, (req, res) => {
    try {
        const {
            userId,
            fromCurrency,
            toCurrency,
            fromAmount,
            toAmount,
            exchangeRate,
            transactionType
        } = req.body;

        // Verify user is executing their own exchange
        if (req.user.userId.toLowerCase() !== userId.toLowerCase()) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        // Normalize userId for database
        const normalizedUserId = userId.toLowerCase();

        // Validation
        if (!fromCurrency || !toCurrency || !fromAmount || fromAmount <= 0) {
            return res.status(400).json({ error: 'Invalid exchange parameters' });
        }

        if (!['buy', 'sell'].includes(transactionType)) {
            return res.status(400).json({ error: 'Invalid transaction type' });
        }

        // Use transaction for atomicity
        const result = db.transaction(() => {
            // Check if source wallet exists and has sufficient balance
            const sourceWallet = walletQueries.findByUserAndCurrency.get(normalizedUserId, fromCurrency);

            if (!sourceWallet) {
                throw new Error('Source wallet not found');
            }

            if (sourceWallet.balance < fromAmount) {
                throw new Error('Insufficient balance');
            }

            // Deduct from source currency
            walletQueries.decrementBalance.run(fromAmount, normalizedUserId, fromCurrency);

            // Add to destination currency
            const toWallet = walletQueries.findByUserAndCurrency.get(normalizedUserId, toCurrency);

            if (toWallet) {
                walletQueries.incrementBalance.run(toAmount, normalizedUserId, toCurrency);
            } else {
                // Create new wallet for destination currency
                const walletId = uuidv4();
                const currencyNames = {
                    PLN: 'Polish Zloty',
                    USD: 'US Dollar',
                    EUR: 'Euro',
                    GBP: 'British Pound',
                    CHF: 'Swiss Franc',
                    JPY: 'Japanese Yen'
                };

                walletQueries.create.run(
                    walletId,
                    normalizedUserId,
                    toCurrency,
                    currencyNames[toCurrency] || toCurrency,
                    toAmount
                );
            }

            // Create transaction record
            const transactionId = uuidv4();
            transactionQueries.create.run(
                transactionId,
                normalizedUserId,
                fromCurrency,
                toCurrency,
                fromAmount,
                toAmount,
                exchangeRate,
                transactionType
            );

            return { transactionId };
        })();

        res.json({
            message: 'Exchange successful',
            transactionId: result.transactionId
        });

    } catch (error) {
        console.error('Exchange error:', error);

        if (error.message === 'Insufficient balance') {
            return res.status(400).json({ error: 'Insufficient balance' });
        }

        res.status(500).json({ error: 'Server error during exchange' });
    }
});

// Get transaction history
router.get('/history/:userId', authenticateToken, (req, res) => {
    try {
        const { userId } = req.params;

        // Verify user is requesting their own history
        if (req.user.userId.toLowerCase() !== userId.toLowerCase()) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        const normalizedUserId = userId.toLowerCase();
        const transactions = transactionQueries.findAllByUser.all(normalizedUserId);
        res.json(transactions);
    } catch (error) {
        console.error('Get history error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
