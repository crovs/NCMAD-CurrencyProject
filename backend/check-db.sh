#!/bin/bash

echo "=== BACKEND DATABASE CHECK ==="
echo ""
echo "Users:"
sqlite3 currency_exchange.db "SELECT id, email, name FROM users;" -header -column
echo ""
echo "Wallets:"
sqlite3 currency_exchange.db "SELECT 
    u.email,
    w.currency_code as currency,
    w.balance,
    datetime(w.updated_at, 'localtime') as updated
FROM currency_wallets w
JOIN users u ON w.user_id = u.id;" -header -column
echo ""
echo "Transactions:"
sqlite3 currency_exchange.db "SELECT 
    u.email,
    from_currency,
    to_currency,
    from_amount,
    type,
    datetime(timestamp, 'localtime') as time
FROM transactions t
JOIN users u ON t.user_id = u.id
ORDER BY timestamp DESC LIMIT 5;" -header -column
