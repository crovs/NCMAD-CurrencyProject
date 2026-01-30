# Currency Exchange Backend API

REST API server for the NCMAD Currency Exchange mobile application.

## Features

- ✅ User authentication (register/login) with JWT
- ✅ Password hashing with bcrypt
- ✅ Multi-currency wallet management
- ✅ Account funding
- ✅ Currency exchange operations
- ✅ Transaction history
- ✅ NBP API integration for live rates
- ✅ SQLite database
- ✅ Protected routes with JWT middleware

## Installation

```bash
cd backend
npm install
```

## Running the Server

### Development (with auto-reload)
```bash
npm run dev
```

### Production
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Authentication

**Register**
```
POST /api/auth/register
Body: { "email": "user@example.com", "password": "password123", "name": "John Doe" }
Response: { "token": "jwt-token", "userId": "uuid", "email": "...", "name": "..." }
```

**Login**
```
POST /api/auth/login
Body: { "email": "user@example.com", "password": "password123" }
Response: { "token": "jwt-token", "userId": "uuid", "email": "...", "name": "..." }
```

**Get Current User** (Protected)
```
GET /api/auth/me
Headers: { "Authorization": "Bearer <token>" }
Response: { "userId": "...", "email": "...", "name": "...", "createdAt": "..." }
```

### Wallet Management

**Get User Wallets** (Protected)
```
GET /api/wallet/:userId
Headers: { "Authorization": "Bearer <token>" }
Response: [...wallets]
```

**Fund Account** (Protected)
```
POST /api/wallet/fund
Headers: { "Authorization": "Bearer <token>" }
Body: { "userId": "uuid", "amount": 1000, "currency": "PLN" }
Response: { "message": "Account funded successfully" }
```

**Get Specific Balance** (Protected)
```
GET /api/wallet/:userId/:currency
Headers: { "Authorization": "Bearer <token>" }
Response: { "id": "...", "balance": 1000, "currency_code": "PLN", ... }
```

### Exchange Operations

**Get Current Rates**
```
GET /api/exchange/rates
Response: NBP API data with all current exchange rates
```

**Execute Exchange** (Protected)
```
POST /api/exchange
Headers: { "Authorization": "Bearer <token>" }
Body: {
  "userId": "uuid",
  "fromCurrency": "PLN",
  "toCurrency": "USD",
  "fromAmount": 100,
  "toAmount": 25,
  "exchangeRate": 4.0,
  "transactionType": "buy"
}
Response: { "message": "Exchange successful", "transactionId": "..." }
```

**Get Transaction History** (Protected)
```
GET /api/exchange/history/:userId
Headers: { "Authorization": "Bearer <token>" }
Response: [...transactions]
```

### System

**Health Check**
```
GET /api/health
Response: { "status": "ok", "timestamp": "...", "service": "Currency Exchange API" }
```

## Database Schema

### users
- id (TEXT PRIMARY KEY)
- email (TEXT UNIQUE)
- password_hash (TEXT)
- name (TEXT)
- created_at (DATETIME)

### currency_wallets
- id (TEXT PRIMARY KEY)
- user_id (TEXT, FOREIGN KEY)
- currency_code (TEXT)
- currency_name (TEXT)
- balance (REAL)
- updated_at (DATETIME)

### transactions
- id (TEXT PRIMARY KEY)
- user_id (TEXT, FOREIGN KEY)
- from_currency (TEXT)
- to_currency (TEXT)
- from_amount (REAL)
- to_amount (REAL)
- exchange_rate (REAL)
- transaction_type (TEXT: 'buy', 'sell', 'fund')
- timestamp (DATETIME)

## Security

- Passwords are hashed using bcrypt (10 salt rounds)
- JWT tokens expire after 30 days
- Protected routes require valid JWT token
- Users can only access their own data
- Database uses foreign key constraints

## Technologies

- **Node.js** - Runtime
- **Express.js** - Web framework
- **better-sqlite3** - SQLite database
- **bcrypt** - Password hashing
- **jsonwebtoken** - JWT authentication
- **cors** - CORS middleware
- **node-fetch** - HTTP requests to NBP API

## Connecting iOS App

Update the iOS app's `Constants.swift`:

```swift
struct Constants {
    struct API {
        static let baseURL = "http://localhost:3000/api"
        // For real device: use your computer's IP
        // static let baseURL = "http://192.168.1.XXX:3000/api"
    }
}
```

## Testing

You can test the API using curl, Postman, or any HTTP client:

```bash
# Register a user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get rates (no auth required)
curl http://localhost:3000/api/exchange/rates
```
