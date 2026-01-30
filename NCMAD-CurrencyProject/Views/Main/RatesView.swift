//
//  RatesView.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

struct RatesView: View {
    @EnvironmentObject var nbpService: NBPService
    @State private var searchText = ""
    @State private var selectedCurrency: CurrencyRate?
    @State private var showHistorical = false
    
    var filteredRates: [CurrencyRate] {
        if searchText.isEmpty {
            return nbpService.currentRates
        } else {
            return nbpService.currentRates.filter { rate in
                rate.currency.localizedCaseInsensitiveContains(searchText) ||
                rate.code.localizedCaseInsensitiveContains(searchText)
            }
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
                        Text("Exchange Rates")
                            .font(.largeTitle.bold())
                            .foregroundColor(.black)
                        
                        Text("Live rates from NBP API")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search currency", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Rates List
                    if nbpService.isLoading {
                        Spacer()
                        ProgressView("Loading rates...")
                        Spacer()
                    } else if filteredRates.isEmpty {
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text(searchText.isEmpty ? "No rates available" : "No results found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        List(filteredRates) { rate in
                            RateRow(rate: rate)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .onTapGesture {
                                    selectedCurrency = rate
                                    showHistorical = true
                                }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .refreshable {
                do {
                    _ = try await nbpService.fetchCurrentRates()
                } catch {
                    print("Failed to refresh rates")
                }
            }
            .sheet(item: $selectedCurrency) { rate in
                HistoricalRatesView(currency: rate)
            }
        }
    }
}

// MARK: - Rate Row
struct RateRow: View {
    let rate: CurrencyRate
    
    var body: some View {
        HStack(spacing: 15) {
            // Currency Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "00d4ff").opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(currencyFlag)
                    .font(.title2)
            }
            
            // Currency Info
            VStack(alignment: .leading, spacing: 4) {
                Text(rate.code)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(rate.currency)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Rate
            VStack(alignment: .trailing, spacing: 4) {
                Text(rate.formattedRate)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text("PLN")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var currencyFlag: String {
        switch rate.code {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "CHF": return "🇨🇭"
        case "JPY": return "🇯🇵"
        case "AUD": return "🇦🇺"
        case "CAD": return "🇨🇦"
        case "SEK": return "🇸🇪"
        case "NOK": return "🇳🇴"
        case "DKK": return "🇩🇰"
        case "CZK": return "🇨🇿"
        case "HUF": return "🇭🇺"
        default: return "💱"
        }
    }
}

// MARK: - Historical Rates View
struct HistoricalRatesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var nbpService: NBPService
    
    let currency: CurrencyRate
    @State private var historicalRates: [HistoricalRate] = []
    @State private var isLoading = false
    @State private var days = 30
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f5f5")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Currency Header
                    VStack(spacing: 10) {
                        Text(currency.code)
                            .font(.largeTitle.bold())
                        
                        Text(currency.currency)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Current: \(currency.formattedRate) PLN")
                            .font(.title3.bold())
                            .foregroundColor(Color(hex: "00d4ff"))
                    }
                    .padding()
                    
                    // Period Selector
                    Picker("Period", selection: $days) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: days) { _, _ in
                        loadHistoricalData()
                    }
                    
                    // Historical Data
                    if isLoading {
                        Spacer()
                        ProgressView("Loading historical data...")
                        Spacer()
                    } else if historicalRates.isEmpty {
                        Spacer()
                        Text("No historical data available")
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        List(historicalRates) { rate in
                            HStack {
                                Text(rate.effectiveDate)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(String(format: "%.4f", rate.mid))
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "00d4ff"))
                            }
                            .padding(.vertical, 5)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Historical Rates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHistoricalData()
            }
        }
    }
    
    private func loadHistoricalData() {
        isLoading = true
        Task {
            do {
                historicalRates = try await nbpService.fetchHistoricalRates(currency: currency.code, days: days)
            } catch {
                print("Failed to load historical rates: \(error)")
            }
            isLoading = false
        }
    }
}

#Preview {
    RatesView()
        .environmentObject(NBPService.shared)
}
