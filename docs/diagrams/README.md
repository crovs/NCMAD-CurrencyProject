# 📊 Project Diagrams - Quick Reference

## Files in this folder:

### Diagrams 
- `uml-use-case-diagram.png` - Shows all features and actors
- `uml-class-diagram-IOS-APP.png` - iOS app architecture (MVVM)
- `uml-class-diagram-BACKEND.png` - Backend architecture (Routes + Database)
- `erd-database-diagram.png` - Database schema with relationships

---

## Quick Explanation

### 1. Use Case Diagram (What the app does)
**Actors:**
- User (end user)
- NBP API (external rates provider)
- Admin (system admin)

**Main Features:**
- Register/Login/Logout
- Fund account (add money)
- View rates (current + historical)
- Buy/Sell currency
- View transaction history
- Change display currency

### 2. Class Diagram - iOS App (How the app is built)
**Architecture:** MVVM (Model-View-ViewModel)

**Models:** User, CurrencyWallet, Transaction, CurrencyRate  
**ViewModels:** AuthViewModel, WalletViewModel, ExchangeViewModel  
**Services:** APIService (backend calls), NBPService (rates), AuthService (login)  
**Views:** LoginView, WalletView, ExchangeView, HistoryView

### 3. Class Diagram - Backend (How the server works)
**Routes:**
- AuthRoutes: /register, /login, /logout
- WalletRoutes: /wallet/:userId, /wallet/fund
- ExchangeRoutes: /exchange, /exchange/rates, /exchange/history
- AdminRoutes: /admin/database

**Database Layer:**
- UserQueries, WalletQueries, TransactionQueries
- All use prepared statements (SQL injection protection)

**Middleware:**
- JWT authentication (protects all routes except login/register)

### 4. ERD Diagram (Database structure)
**3 Tables:**

1. **users**
   - id (UUID), email (unique), password_hash, name, created_at

2. **currency_wallets**
   - id (UUID), user_id (FK → users), currency_code, balance, updated_at

3. **transactions**
   - id (UUID), user_id (FK → users), from_currency, to_currency, amounts, type, timestamp

**Relationships:**
- One user → Many wallets (1:N)
- One user → Many transactions (1:N)
- Foreign keys with CASCADE delete

---

## Database Schema (SQL)

```sql
-- Users
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Wallets
CREATE TABLE currency_wallets (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    currency_code TEXT NOT NULL,
    balance REAL DEFAULT 0.0,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Transactions
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    from_currency TEXT NOT NULL,
    to_currency TEXT NOT NULL,
    from_amount REAL NOT NULL,
    to_amount REAL NOT NULL,
    exchange_rate REAL NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('fund', 'buy', 'sell')),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## API Endpoints

### Authentication
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Login (returns JWT)
- `POST /api/auth/logout` - Logout

### Wallet
- `GET /api/wallet/:userId` - Get all wallets
- `POST /api/wallet/fund` - Add funds
- `GET /api/wallet/balance/:userId/:currency` - Get balance

### Exchange
- `GET /api/exchange/rates` - Get NBP rates
- `POST /api/exchange` - Execute exchange
- `GET /api/exchange/history/:userId` - Transaction history

### Admin
- `GET /api/admin/database` - Database viewer data

---

## Key Features

✅ **30+ currencies** from NBP API  
✅ **JWT authentication** for security  
✅ **Multi-currency wallets**  
✅ **Real-time exchange rates**  
✅ **Transaction history**  
✅ **SQLite database** with referential integrity  
✅ **MVVM architecture** (iOS)  
✅ **RESTful API** (Backend)

---

## Tech Stack

**Frontend:** Swift + SwiftUI + SwiftData  
**Backend:** Node.js + Express + better-sqlite3  
**External API:** NBP (National Bank of Poland)  
**Authentication:** JWT + bcrypt  
**Database:** SQLite

---

*For full details, see walkthrough.md*
