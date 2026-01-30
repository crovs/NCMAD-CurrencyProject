//
//  WalletView.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var walletViewModel: WalletViewModel
    @State private var showFundSheet = false
    @State private var showProfileMenu = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "f5f5f5")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header with Profile
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Wallet")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            // Refresh Button
                            Button(action: {
                                Task {
                                    await walletViewModel.refreshBalances()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "00d4ff"))
                                    .padding(10)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 5)
                            }
                            
                            // Profile Button
                            Button(action: {
                                showProfileMenu = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "00d4ff"), Color(hex: "0099ff")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 45, height: 45)
                                    
                                    Text(authViewModel.currentUser?.name.prefix(1).uppercased() ?? "U")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Total Balance Card
                        VStack(spacing: 15) {
                            Text("Total Balance")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("$\(formattedBalance)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Action Buttons
                            HStack(spacing: 20) {
                                ActionButton(icon: "plus", title: "Top up") {
                                    showFundSheet = true
                                }
                                
                                ActionButton(icon: "ellipsis", title: "More") {
                                    // More actions
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                        .padding(.horizontal)
                        
                        // Currency Holdings
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("My Currencies")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Text("$\(formattedBalance)")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            
                            if walletViewModel.wallets.isEmpty {
                                EmptyWalletView()
                            } else {
                                ForEach(walletViewModel.wallets) { wallet in
                                    CurrencyCard(wallet: wallet)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await walletViewModel.refreshBalances()
                }
            }
            .sheet(isPresented: $showFundSheet) {
                FundAccountSheet()
            }
            .confirmationDialog("Account", isPresented: $showProfileMenu) {
                Button("Log Out", role: .destructive) {
                    authViewModel.logout()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: walletViewModel.totalBalancePLN as NSDecimalNumber) ?? "0.00"
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "00d4ff"))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Empty Wallet View
struct EmptyWalletView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No currencies yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Top up your account to get started")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}

// MARK: - Fund Account Sheet
struct FundAccountSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletViewModel: WalletViewModel
    
    @State private var amount = ""
    @State private var selectedCurrency = "PLN"
    
    let currencies = ["PLN", "USD", "EUR", "GBP"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Currency") {
                    Picker("Select Currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Fund Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Funds") {
                        addFunds()
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func addFunds() {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            return
        }
        
        Task {
            await walletViewModel.fundAccount(amount: amountValue, currency: selectedCurrency)
            dismiss()
        }
    }
}

#Preview {
    WalletView()
        .environmentObject(AuthViewModel())
        .environmentObject(WalletViewModel())
}
