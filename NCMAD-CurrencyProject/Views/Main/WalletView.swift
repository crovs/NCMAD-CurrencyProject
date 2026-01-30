//
//  WalletView.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var nbpService: NBPService
    @State private var showFundSheet = false
    @State private var showMoreOptions = false
    @State private var showCurrencyPicker = false
    @State private var displayCurrency = "PLN"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f5f5")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Total Balance Card (TALLER)
                        VStack(spacing: 20) {
                            HStack {
                                Text("Total Balance")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Spacer()
                                
                                Button(action: {
                                    showMoreOptions = true
                                }) {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text(walletViewModel.formattedTotalBalance)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("in \(displayCurrency)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Action Button (only Top Up, refresh via pull-down)
                            Button(action: {
                                showFundSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Top Up")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        .padding(30)
                        .frame(minHeight: 240)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "00d4ff"), Color(hex: "0099ff")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(hex: "00d4ff").opacity(0.3), radius: 15)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Currency Holdings
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Your Currencies")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            if walletViewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                            } else if walletViewModel.wallets.isEmpty {
                                EmptyWalletView()
                            } else {
                                ForEach(walletViewModel.wallets, id: \.id) { wallet in
                                    CurrencyCard(wallet: wallet)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .refreshable {
                    print("🔄 Pull to refresh triggered")
                    walletViewModel.loadWallets()
                    await walletViewModel.refreshBalances()
                }
            }
            .navigationTitle("Wallet")
            .sheet(isPresented: $showFundSheet) {
                CompactFundAccountSheet(isPresented: $showFundSheet)
                    .environmentObject(walletViewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog("More Options", isPresented: $showMoreOptions) {
                Button("Change Currency") {
                    showCurrencyPicker = true
                }
                Button("View Statement") {}
                Button("Export Data") {}
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerSheet(selectedCurrency: $displayCurrency)
            }
            .onAppear {
                print("👀 WalletView appeared")
                walletViewModel.loadWallets()
                Task {
                    await walletViewModel.refreshBalances()
                }
            }
        }
    }
}

// MARK: - Compact Fund Account Sheet
struct CompactFundAccountSheet: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var nbpService: NBPService
    @Binding var isPresented: Bool
    @State private var amount: String = ""
    @State private var selectedCurrency: String = "PLN"
    
    // All available currencies from NBP
    var availableCurrencies: [String] {
        var currencies = ["PLN"] // PLN is base currency
        currencies.append(contentsOf: nbpService.currentRates.map { $0.code }.sorted())
        return currencies
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Title
            Text("Add Funds")
                .font(.title2.bold())
            
            // Currency Picker (Wheel style)
            HStack {
                Text("Currency")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Picker("", selection: $selectedCurrency) {
                    ForEach(availableCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "0099ff"))
            }
            .padding(.horizontal)
            
            // Amount Input
            HStack {
                Text(selectedCurrency)
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.leading)
                
                TextField("0", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing)
            }
            .frame(height: 60)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Quick Amount Buttons
            HStack(spacing: 10) {
                ForEach([100, 500, 1000], id: \.self) { value in
                    Button(action: {
                        amount = "\(value)"
                    }) {
                        Text("+\(value)")
                            .font(.subheadline.bold())
                            .foregroundColor(Color(hex: "0099ff"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "0099ff").opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // Confirm Button
            Button(action: {
                fundAccount()
            }) {
                Text(walletViewModel.isLoading ? "Processing..." : "Confirm")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "00d4ff"), Color(hex: "0099ff")],
                            startPoint: .leading,
                            endPoint: .trailing)
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(walletViewModel.isLoading || amount.isEmpty)
            
            Spacer()
        }
        .padding(.bottom, 20)
    }
    
    private func fundAccount() {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            print("⚠️ Invalid amount: \(amount)")
            return
        }
        
        print("💰 Funding account: \(amountValue) \(selectedCurrency)")
        
        Task {
            await walletViewModel.fundAccount(amount: amountValue, currency: selectedCurrency)
            
            // Wait for UI to update
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Close sheet
            isPresented = false
            amount = ""
            print("✅ Fund sheet closed")
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
        .padding(.vertical, 40)
    }
}

#Preview {
    WalletView()
        .environmentObject(WalletViewModel())
        .environmentObject(NBPService.shared)
}
