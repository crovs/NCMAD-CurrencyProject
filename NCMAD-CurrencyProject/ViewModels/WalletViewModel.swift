//
//  WalletViewModel.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
class WalletViewModel: ObservableObject {
    @Published var wallets: [CurrencyWallet] = []
    @Published var totalBalancePLN: Decimal = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let nbpService = NBPService.shared
    var modelContext: ModelContext? // Made public for ExchangeViewModel setup
    private var userId: UUID?
    
    var formattedTotalBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let number = NSDecimalNumber(decimal: totalBalancePLN)
        return "\(formatter.string(from: number) ?? "0.00") PLN"
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func setUserId(_ id: UUID) {
        self.userId = id
        loadWallets()
    }
    
    func loadWallets() {
        guard let context = modelContext, let userId = userId else { return }
        
        let descriptor = FetchDescriptor<CurrencyWallet>(
            predicate: #Predicate { wallet in
                wallet.userId == userId
            },
            sortBy: [SortDescriptor(\.currencyCode)]
        )
        
        if let fetchedWallets = try? context.fetch(descriptor) {
            wallets = fetchedWallets
            calculateTotalBalance()
        }
    }
    
    func fundAccount(amount: Decimal, currency: String = "PLN") async {
        print("🔷 fundAccount called: \(amount) \(currency)")
        print("🔷 userId: \(String(describing: userId))")
        
        guard let userId = userId else {
            print("❌ No userId set!")
            errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("📡 Calling backend API...")
            // Call backend API
            try await apiService.fundAccount(
                userId: userId.uuidString,
                amount: Double(truncating: amount as NSDecimalNumber),
                currency: currency
            )
            print("✅ Backend API call successful")
            
            // Update local wallet
            print("💾 Updating local wallet...")
            updateWalletBalance(currency: currency, amount: amount)
            print("✅ Wallet balance updated")
            
            // Create transaction record
            print("📝 Creating transaction record...")
            createFundTransaction(amount: amount, currency: currency)
            print("✅ Transaction created")
            
            // Reload wallets to refresh UI
            print("🔄 Reloading wallets...")
            loadWallets()
            print("✅ Wallets reloaded. Count: \(wallets.count)")
            
        } catch {
            print("❌ Error funding account: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("🔷 fundAccount completed")
    }
    
    func updateWalletBalance(currency: String, amount: Decimal) {
        guard let context = modelContext, let userId = userId else { return }
        
        // Find existing wallet or create new one
        if let existingWallet = wallets.first(where: { $0.currencyCode == currency }) {
            existingWallet.balance += amount
            existingWallet.updatedAt = Date()
        } else {
            let newWallet = CurrencyWallet(
                userId: userId,
                currencyCode: currency,
                currencyName: getCurrencyName(for: currency),
                balance: amount
            )
            context.insert(newWallet)
            wallets.append(newWallet)
        }
        
        try? context.save()
        calculateTotalBalance()
    }
    
    func deductBalance(currency: String, amount: Decimal) -> Bool {
        guard let wallet = wallets.first(where: { $0.currencyCode == currency }) else {
            return false
        }
        
        if wallet.balance >= amount {
            wallet.balance -= amount
            wallet.updatedAt = Date()
            try? modelContext?.save()
            calculateTotalBalance()
            return true
        }
        
        return false
    }
    
    func getBalance(for currency: String) -> Decimal {
        return wallets.first(where: { $0.currencyCode == currency })?.balance ?? 0
    }
    
    private func calculateTotalBalance() {
        var total: Decimal = 0
        
        for wallet in wallets {
            if wallet.currencyCode == "PLN" {
                total += wallet.balance
            } else {
                // Convert to PLN using NBP rates
                if let rate = nbpService.getExchangeRate(for: wallet.currencyCode) {
                    total += wallet.balance * Decimal(rate)
                }
            }
        }
        
        totalBalancePLN = total
    }
    
    private func createFundTransaction(amount: Decimal, currency: String) {
        guard let context = modelContext, let userId = userId else { return }
        
        let transaction = Transaction(
            userId: userId,
            fromCurrency: "SYSTEM",
            toCurrency: currency,
            fromAmount: amount,
            toAmount: amount,
            exchangeRate: 1.0,
            type: .fund
        )
        
        context.insert(transaction)
        try? context.save()
    }
    
    private func getCurrencyName(for code: String) -> String {
        let currencyNames: [String: String] = [
            "PLN": "Polish Zloty",
            "USD": "US Dollar",
            "EUR": "Euro",
            "GBP": "British Pound",
            "CHF": "Swiss Franc",
            "JPY": "Japanese Yen"
        ]
        return currencyNames[code] ?? code
    }
    
    func refreshBalances() async {
        // Refresh NBP rates first
        do {
            _ = try await nbpService.fetchCurrentRates()
            calculateTotalBalance()
        } catch {
            errorMessage = "Failed to refresh exchange rates"
        }
    }
}
