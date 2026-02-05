# 💰 NCMAD Currency Exchange Project

A comprehensive mobile currency exchange system built for iOS, enabling users to manage multi-currency wallets, trade in real-time with NBP (National Bank of Poland) rates, and track their transaction history.

## 🚀 Features

### 📱 iOS Mobile App
*   **Secure Authentication:** User registration and login utilizing JWT tokens.
*   **Multi-Currency Wallet:** Manage balances in PLN, USD, EUR, GBP, CHF, and JPY.
*   **Real-Time Exchange:** Live currency rates fetched directly from the NBP API.
*   **Instant Transactions:** Buy and sell currencies seamlessly with automatic balance updates.
*   **Historical Data:** View currency trends over the last 30 days.
*   **Transaction History:** A detailed log of all your funding and exchange activities.
*   **Settings:** Manage your profile and secure logout.

### 🌐 Backend Node.js Server
*   **RESTful API:** Robust endpoints for auth, wallet management, and transactions.
*   **Live Database Viewer:** A web dashboard (`http://localhost:3000`) to visualize database state in real-time.
*   **Atomic Transactions:** Ensures data integrity during money transfers.
*   **Persistent Storage:** SQLite database for reliable data retention.

---

## 🛠️ Tech Stack

*   **iOS Client:** Swift 6, SwiftUI, Combine, MVVM Architecture, SwiftData (Local Caching).
*   **Backend:** Node.js, Express.js.
*   **Database:** SQLite (via `better-sqlite3`).
*   **External API:** NBP Web API (National Bank of Poland).

---

## 🏃‍♂️ How to Run the Project

### Prerequisites
*   **macOS** with **Xcode 16+** installed.
*   **Node.js** (v18 or newer) installed.

### 1. Start the Backend Server
The iOS app relies on this server for all data.

1.  Open your terminal.
2.  Navigate to the backend folder:
    ```bash
    cd backend
    ```
3.  Install dependencies (first time only):
    ```bash
    npm install
    ```
4.  Start the server:
    ```bash
    npm start
    ```
    ✅ You should see: `Server running on: http://localhost:3000`

### 2. Run the iOS App
1.  Open `NCMAD-CurrencyProject.xcodeproj` in Xcode.
2.  Select a Simulator (e.g., iPhone 15 Pro).
3.  Press **Cmd + R** to build and run.

---

## 🖥️ Live Database Dashboard

For demonstration purposes, the backend includes a web interface to view the database in real-time.
*   Open **[http://localhost:3000](http://localhost:3000)** in your browser.
*   You can watch users and transactions appear here as you interact with the mobile app!

---

## 📂 Project Structure

*   `NCMAD-CurrencyProject/` - iOS Application Source Code (SwiftUI).
*   `backend/` - Node.js Server & Database.
*   `docs/` - Diagrams (UML, ERD) and Walkthrough documentation.

## 📝 License
Created for NCMAD Course Project.
