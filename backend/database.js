const Database = require('better-sqlite3');
const path = require('path');

// Create database connection
const db = new Database(path.join(__dirname, 'currency_exchange.db'));

// Enable foreign keys
db.pragma('foreign_keys = ON');

// Initialize database schema
function initializeDatabase() {
  // Users table
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      name TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Currency wallets table
  db.exec(`
    CREATE TABLE IF NOT EXISTS currency_wallets (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      currency_code TEXT NOT NULL,
      currency_name TEXT NOT NULL,
      balance REAL DEFAULT 0,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      UNIQUE(user_id, currency_code)
    )
  `);

  // Transactions table
  db.exec(`
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      from_currency TEXT NOT NULL,
      to_currency TEXT NOT NULL,
      from_amount REAL NOT NULL,
      to_amount REAL NOT NULL,
      exchange_rate REAL NOT NULL,
      transaction_type TEXT NOT NULL,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  console.log('✅ Database initialized successfully');
}

// Initialize first
initializeDatabase();

// User queries
const userQueries = {
  create: db.prepare(`
    INSERT INTO users (id, email, password_hash, name)
    VALUES (?, ?, ?, ?)
  `),

  findByEmail: db.prepare(`
    SELECT * FROM users WHERE email = ?
  `),

  findById: db.prepare(`
    SELECT * FROM users WHERE id = ?
  `)
};

// Wallet queries
const walletQueries = {
  create: db.prepare(`
    INSERT INTO currency_wallets (id, user_id, currency_code, currency_name, balance)
    VALUES (?, ?, ?, ?, ?)
  `),

  findByUserAndCurrency: db.prepare(`
    SELECT * FROM currency_wallets
    WHERE user_id = ? AND currency_code = ?
  `),

  findAllByUser: db.prepare(`
    SELECT * FROM currency_wallets
    WHERE user_id = ?
    ORDER BY currency_code
  `),

  updateBalance: db.prepare(`
    UPDATE currency_wallets
    SET balance = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `),

  incrementBalance: db.prepare(`
    UPDATE currency_wallets
    SET balance = balance + ?, updated_at = CURRENT_TIMESTAMP
    WHERE user_id = ? AND currency_code = ?
  `),

  decrementBalance: db.prepare(`
    UPDATE currency_wallets
    SET balance = balance - ?, updated_at = CURRENT_TIMESTAMP
    WHERE user_id = ? AND currency_code = ?
  `)
};

// Transaction queries
const transactionQueries = {
  create: db.prepare(`
    INSERT INTO transactions (id, user_id, from_currency, to_currency, from_amount, to_amount, exchange_rate, transaction_type)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `),

  findAllByUser: db.prepare(`
    SELECT * FROM transactions
    WHERE user_id = ?
    ORDER BY timestamp DESC
  `),

  findById: db.prepare(`
    SELECT * FROM transactions WHERE id = ?
  `)
};

module.exports = {
  db,
  initializeDatabase,
  userQueries,
  walletQueries,
  transactionQueries
};
