//
//  ExchangeView.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

struct ExchangeView: View {
    @EnvironmentObject var exchangeViewModel: ExchangeViewModel
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var nbpService: NBPService
    
    var availableCurrencies: [String] {
        var currencies = ["PLN"]
        currencies.append(contentsOf: nbpService.currentRates.map { $0.code }.sorted())
        return currencies
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f5f5")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        Text("Exchange")
                            .font(.largeTitle.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Exchange Card
                        VStack(spacing: 20) {
                            // From Currency
                            VStack(spacing: 10) {
                                HStack {
                                    Text("From")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("Balance: \(walletViewModel.getBalance(for: exchangeViewModel.fromCurrency).description)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 15) {
                                    // Currency Picker
                                    Menu {
                                        ForEach(availableCurrencies, id: \.self) { currency in
                                            Button(action: {
                                                exchangeViewModel.fromCurrency = currency
                                                exchangeViewModel.updateExchangeRate()
                                            }) {
                                                Text(currency)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(exchangeViewModel.fromCurrency)
                                                .font(.title2.bold())
                                                .foregroundColor(.black)
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(12)
                                    }
                                    
                                    // Amount Input
                                    TextField("0.00", text: $exchangeViewModel.fromAmount)
                                        .font(.title2.bold())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .onChange(of: exchangeViewModel.fromAmount) { _, _ in
                                            exchangeViewModel.calculateToAmount()
                                        }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            
                            // Swap Button
                            Button(action: {
                                exchangeViewModel.swapCurrencies()
                            }) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "00d4ff"), Color(hex: "0099ff")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Circle())
                            }
                            
                            // To Currency
                            VStack(spacing: 10) {
                                HStack {
                                    Text("To")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("Balance: \(walletViewModel.getBalance(for: exchangeViewModel.toCurrency).description)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 15) {
                                    // Currency Picker
                                    Menu {
                                        ForEach(availableCurrencies, id: \.self) { currency in
                                            Button(action: {
                                                exchangeViewModel.toCurrency = currency
                                                exchangeViewModel.updateExchangeRate()
                                            }) {
                                                Text(currency)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(exchangeViewModel.toCurrency)
                                                .font(.title2.bold())
                                                .foregroundColor(.black)
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(12)
                                    }
                                    
                                    // Amount Display
                                    Text(exchangeViewModel.toAmount.isEmpty ? "0.00" : exchangeViewModel.toAmount)
                                        .font(.title2.bold())
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            
                            // Exchange Rate Info
                            if exchangeViewModel.currentRate > 0 {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(Color(hex: "00d4ff"))
                                    Text("Rate: 1 \(exchangeViewModel.fromCurrency) = \(String(format: "%.4f", Double(truncating: exchangeViewModel.currentRate as NSDecimalNumber))) \(exchangeViewModel.toCurrency)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1a1a2e").opacity(0.05), Color(hex: "16213e").opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Error/Success Messages
                        if let error = exchangeViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        
                        if let success = exchangeViewModel.successMessage {
                            Text(success)
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 15) {
                            // Buy Button
                            Button(action: {
                                Task {
                                    await exchangeViewModel.executeBuy()
                                }
                            }) {
                                HStack {
                                    if exchangeViewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Buy \(exchangeViewModel.toCurrency)")
                                    }
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .disabled(exchangeViewModel.isLoading || exchangeViewModel.fromAmount.isEmpty)
                            
                            // Sell Button
                            Button(action: {
                                Task {
                                    await exchangeViewModel.executeSell()
                                }
                            }) {
                                HStack {
                                    if exchangeViewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "arrow.up.circle.fill")
                                        Text("Sell \(exchangeViewModel.fromCurrency)")
                                    }
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .disabled(exchangeViewModel.isLoading || exchangeViewModel.fromAmount.isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                exchangeViewModel.updateExchangeRate()
            }
        }
    }
}

#Preview {
    ExchangeView()
        .environmentObject(ExchangeViewModel())
        .environmentObject(WalletViewModel())
        .environmentObject(NBPService.shared)
}
