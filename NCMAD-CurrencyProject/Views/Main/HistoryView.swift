//
//  HistoryView.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Query(sort: \Transaction.timestamp, order: .reverse) private var transactions: [Transaction]
    
    @State private var selectedFilter = TransactionFilter.all
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case buy = "Buy"
        case sell = "Sell"
        case fund = "Fund"
    }
    
    var filteredTransactions: [Transaction] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        
        let userTransactions = transactions.filter { $0.userId == userId }
        
        switch selectedFilter {
        case .all:
            return userTransactions
        case .buy:
            return userTransactions.filter { $0.type == .buy }
        case .sell:
            return userTransactions.filter { $0.type == .sell }
        case .fund:
            return userTransactions.filter { $0.type == .fund }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f5f5")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Transaction History")
                            .font(.largeTitle.bold())
                            .foregroundColor(.black)
                        
                        Text("\(filteredTransactions.count) transactions")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Filter
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(TransactionFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // Transactions List
                    if filteredTransactions.isEmpty {
                        Spacer()
                        EmptyHistoryView()
                        Spacer()
                    } else {
                        List(filteredTransactions) { transaction in
                            TransactionRow(transaction: transaction)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 15) {
            // Transaction Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            
            // Transaction Info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(amountText)
                    .font(.headline)
                    .foregroundColor(amountColor)
                
                Text(rateText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var iconName: String {
        switch transaction.type {
        case .buy:
            return "arrow.down.circle.fill"
        case .sell:
            return "arrow.up.circle.fill"
        case .fund:
            return "plus.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .buy:
            return .green
        case .sell:
            return .red
        case .fund:
            return Color(hex: "00d4ff")
        }
    }
    
    private var amountText: String {
        let fromAmountStr = String(format: "%.2f", Double(truncating: transaction.fromAmount as NSDecimalNumber))
        let toAmountStr = String(format: "%.2f", Double(truncating: transaction.toAmount as NSDecimalNumber))
        
        switch transaction.type {
        case .fund:
            return "+\(toAmountStr) \(transaction.toCurrency)"
        case .buy, .sell:
            return "\(fromAmountStr) \(transaction.fromCurrency) → \(toAmountStr) \(transaction.toCurrency)"
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .fund, .buy:
            return .green
        case .sell:
            return .red
        }
    }
    
    private var rateText: String {
        if transaction.type == .fund {
            return "Account Funding"
        }
        return "Rate: \(String(format: "%.4f", Double(truncating: transaction.exchangeRate as NSDecimalNumber)))"
    }
}

// MARK: - Empty History View
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "clock.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No transactions yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Your exchange history will appear here")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    HistoryView()
        .environmentObject(AuthViewModel())
}
