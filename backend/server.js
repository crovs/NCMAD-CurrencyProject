const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { initializeDatabase } = require('./database');
const authRoutes = require('./routes/auth');
const walletRoutes = require('./routes/wallet');
const exchangeRoutes = require('./routes/exchange');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Initialize database
initializeDatabase();

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/exchange', exchangeRoutes);

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        service: 'Currency Exchange API'
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        name: 'Currency Exchange REST API',
        version: '1.0.0',
        endpoints: {
            auth: {
                register: 'POST /api/auth/register',
                login: 'POST /api/auth/login',
                me: 'GET /api/auth/me'
            },
            wallet: {
                getWallets: 'GET /api/wallet/:userId',
                fundAccount: 'POST /api/wallet/fund',
                getBalance: 'GET /api/wallet/:userId/:currency'
            },
            exchange: {
                getRates: 'GET /api/exchange/rates',
                execute: 'POST /api/exchange',
                history: 'GET /api/exchange/history/:userId'
            },
            health: 'GET /api/health'
        }
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: err.message
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not found',
        path: req.path
    });
});

// Start server
app.listen(PORT, () => {
    console.log('');
    console.log('='.repeat(50));
    console.log('🚀 Currency Exchange API Server');
    console.log('='.repeat(50));
    console.log(`📡 Server running on: http://localhost:${PORT}`);
    console.log(`📊 API Documentation: http://localhost:${PORT}/`);
    console.log(`❤️  Health Check: http://localhost:${PORT}/api/health`);
    console.log('='.repeat(50));
    console.log('');
});

module.exports = app;
