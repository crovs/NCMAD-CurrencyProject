#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===================================="
echo "Currency Exchange - Debug Tool"
echo -e "====================================${NC}\n"

# 1. Check if server is running
echo -e "${YELLOW}1. Checking server status...${NC}"
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo -e "${GREEN}✓ Server is running${NC}\n"
else
    echo -e "${RED}✗ Server is NOT running${NC}\n"
    exit 1
fi

# 2. Show all users
echo -e "${YELLOW}2. Database - Users:${NC}"
sqlite3 currency_exchange.db "SELECT substr(id, 1, 8) || '...' as id, email, name FROM users;" -header -column
echo ""

# 3. Show all wallets
echo -e "${YELLOW}3. Database - Currency Wallets:${NC}"
WALLET_COUNT=$(sqlite3 currency_exchange.db "SELECT COUNT(*) FROM currency_wallets;")
if [ "$WALLET_COUNT" -eq 0 ]; then
    echo -e "${RED}No wallets found${NC}"
else
    sqlite3 currency_exchange.db "SELECT 
        substr(user_id, 1, 8) || '...' as user_id,
        currency_code,
        balance,
        datetime(updated_at, 'localtime') as updated
    FROM currency_wallets ORDER BY updated_at DESC;" -header -column
fi
echo ""

# 4. Show recent transactions
echo -e "${YELLOW}4. Database - Recent Transactions:${NC}"  
TX_COUNT=$(sqlite3 currency_exchange.db "SELECT COUNT(*) FROM transactions;")
if [ "$TX_COUNT" -eq 0 ]; then
    echo -e "${RED}No transactions found${NC}"
else
    sqlite3 currency_exchange.db "SELECT 
        substr(user_id, 1, 8) || '...' as user_id,
        from_currency,
        to_currency,
        from_amount,
        to_amount,
        type,
        datetime(timestamp, 'localtime') as time
    FROM transactions ORDER BY timestamp DESC LIMIT 10;" -header -column
fi
echo ""

# 5. Test fund account endpoint
echo -e "${YELLOW}5. Testing backend API...${NC}"
echo "Press Enter to test funding account, or Ctrl+C to exit"
read

# Get first user
USER_ID=$(sqlite3 currency_exchange.db "SELECT id FROM users LIMIT 1;")
if [ -z "$USER_ID" ]; then
    echo -e "${RED}No users found in database${NC}"
    exit 1
fi

echo -e "${BLUE}Testing fund account for user: ${USER_ID}${NC}"

# Register/Login to get token
echo -e "${BLUE}Logging in...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"ahmetyada4@gmail.com\",
    \"password\": \"123456\"
  }")

TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))")

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Failed to get auth token${NC}"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Got auth token${NC}"

# Fund account
echo -e "${BLUE}Funding account with 1000 PLN...${NC}"
FUND_RESPONSE=$(curl -s -X POST http://localhost:3000/api/wallet/fund \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"amount\": 1000,
    \"currency\": \"PLN\"
  }")

echo "Response:"
echo $FUND_RESPONSE | python3 -m json.tool

echo ""
echo -e "${YELLOW }6. Checking database after funding:${NC}"
sqlite3 currency_exchange.db "SELECT currency_code, balance FROM currency_wallets WHERE user_id = '$USER_ID';" -header -column

echo ""
echo -e "${GREEN}Debug complete!${NC}"
