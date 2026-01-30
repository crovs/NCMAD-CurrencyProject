//
//  CurrencyPickerSheet.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

// MARK: - Currency Picker Sheet
struct CurrencyPickerSheet: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var nbpService: NBPService
    
    var availableCurrencies: [String] {
        var currencies = ["PLN"]
        currencies.append(contentsOf: nbpService.currentRates.map { $0.code }.sorted())
        return currencies
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableCurrencies, id: \.self) { currency in
                    Button(action: {
                        selectedCurrency = currency
                        dismiss()
                    }) {
                        HStack {
                            Text(currencyFlag(currency))
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(currency)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let rate = nbpService.currentRates.first(where: { $0.code == currency }) {
                                    Text(rate.currency)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else if currency == "PLN" {
                                    Text("Polish Zloty")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedCurrency == currency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "00d4ff"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Display Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    
    private func currencyFlag(_ code: String) -> String {
        let flagMap: [String: String] = [
            "PLN": "🇵🇱", "USD": "🇺🇸", "EUR": "🇪🇺", "GBP": "🇬🇧",
            "CHF": "🇨🇭", "JPY": "🇯🇵", "AUD": "🇦🇺", "CAD": "🇨🇦",
            "NZD": "🇳🇿", "SEK": "🇸🇪", "NOK": "🇳🇴", "DKK": "🇩🇰",
            "CZK": "🇨🇿", "HUF": "🇭🇺", "RON": "🇷🇴", "BGN": "🇧🇬",
            "TRY": "🇹🇷", "ILS": "🇮🇱", "CLP": "🇨🇱", "PHP": "🇵🇭",
            "MXN": "🇲🇽", "ZAR": "🇿🇦", "BRL": "🇧🇷", "MYR": "🇲🇾",
            "RUB": "🇷🇺", "IDR": "🇮🇩", "INR": "🇮🇳", "KRW": "🇰🇷",
            "CNY": "🇨🇳", "XDR": "🌍", "HKD": "🇭🇰", "THB": "🇹🇭",
            "SGD": "🇸🇬", "ISK": "🇮🇸", "HRK": "🇭🇷", "UAH": "🇺🇦"
        ]
        return flagMap[code] ?? "💰"
    }
}
