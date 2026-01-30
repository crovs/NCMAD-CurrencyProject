//
//  ExchangeViewModel.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
class ExchangeViewModel: ObservableObject {
    @Published var fromCurrency = "PLN"
    @Published var toCurrency = "USD"
    @Published var fromAmount: String = ""
    @Published var toAmount: String = ""
    @Published var currentRate: Decimal = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let apiService = APIService.shared
    private let nbpService = NBPService.shared
    private var walletViewModel: WalletViewModel?
    private var modelContext: ModelContext?
    private var userId: UUID?
    
    func setDependencies(walletViewModel: WalletViewModel, modelContext: ModelContext, userId: UUID) {
        self.walletViewModel = walletViewModel
        self.modelContext = modelContext
        self.userId = userId
    }
    
    func updateExchangeRate() {
        guard let rate = nbpService.convertCurrency(amount: 1, from: fromCurrency, to: toCurrency) else {
            currentRate = 0
            return
        }
        currentRate = rate
        
        // Update toAmount if fromAmount is set
        if let amount = Decimal(string: fromAmount), amount > 0 {
            calculateToAmount()
        }
    }
    
    func calculateToAmount() {
        guard let amount = Decimal(string: fromAmount), amount > 0 else {
            toAmount = ""
            return
        }
        
        if let converted = nbpService.convertCurrency(amount: amount, from: fromCurrency, to: toCurrency) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 6
            toAmount = formatter.string(from: converted as NSDecimalNumber) ?? ""
        }
    }
    
    func calculateFromAmount() {
        guard let amount = Decimal(string: toAmount), amount > 0 else {
            fromAmount = ""
            return
        }
        
        if let converted = nbpService.convertCurrency(amount: amount, from: toCurrency, to: fromCurrency) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 6
            fromAmount = formatter.string(from: converted as NSDecimalNumber) ?? ""
        }
    }
    
    func swapCurrencies() {
        let temp = fromCurrency
        fromCurrency = toCurrency
        toCurrency = temp
        
        let tempAmount = fromAmount
        fromAmount = toAmount
        toAmount = tempAmount
        
        updateExchangeRate()
    }
    
    func executeBuy() async {
        await executeExchange(type: .buy)
    }
    
    func executeSell() async {
        await executeExchange(type: .sell)
    }
    
    private func executeExchange(type: TransactionType) async {
        guard let userId = userId,
              let walletVM = walletViewModel,
              let context = modelContext else {
            errorMessage = "System error: Missing dependencies"
            return
        }
        
        guard let fromAmt = Decimal(string: fromAmount),
              let toAmt = Decimal(string: toAmount),
              fromAmt > 0, toAmt > 0 else {
            errorMessage = "Please enter valid amounts"
            return
        }
        
        // Check if user has sufficient balance
        let currentBalance = walletVM.getBalance(for: fromCurrency)
        if currentBalance < fromAmt {
            errorMessage = "Insufficient balance in \(fromCurrency). Available: \(currentBalance)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Call backend API
            try await apiService.executeExchange(
                userId: userId.uuidString,
                fromCurrency: fromCurrency,
                toCurrency: toCurrency,
                fromAmount: Double(truncating: fromAmt as NSDecimalNumber),
                toAmount: Double(truncating: toAmt as NSDecimalNumber),
                exchangeRate: Double(truncating: currentRate as NSDecimalNumber),
                type: type
            )
            
            // Update local wallets
            if walletVM.deductBalance(currency: fromCurrency, amount: fromAmt) {
                walletVM.updateWalletBalance(currency: toCurrency, amount: toAmt)
                
                // Create transaction record
                createTransaction(fromAmount: fromAmt, toAmount: toAmt, type: type)
                
                successMessage = "Exchange successful! \(fromAmt) \(fromCurrency) → \(toAmt) \(toCurrency)"
                
                // Clear amounts
                fromAmount = ""
                toAmount = ""
                
            } else {
                errorMessage = "Failed to deduct balance"
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func createTransaction(fromAmount: Decimal, toAmount: Decimal, type: TransactionType) {
        guard let context = modelContext, let userId = userId else { return }
        
        let transaction = Transaction(
            userId: userId,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            fromAmount: fromAmount,
            toAmount: toAmount,
            exchangeRate: currentRate,
            type: type
        )
        
        context.insert(transaction)
        try? context.save()
    }
}
