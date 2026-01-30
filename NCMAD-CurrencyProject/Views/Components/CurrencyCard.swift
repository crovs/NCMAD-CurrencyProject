//
//  CurrencyCard.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import SwiftUI

struct CurrencyCard: View {
    let wallet: CurrencyWallet
    
    var body: some View {
        HStack(spacing: 15) {
            // Currency Icon
            ZStack {
                Circle()
                    .fill(currencyColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(currencyIcon)
                    .font(.title2)
            }
            
            // Currency Info
            VStack(alignment: .leading, spacing: 4) {
                Text(wallet.currencyName)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text("\(wallet.balanceString) \(wallet.currencyCode)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Balance in wallet currency
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currencySymbol)\(wallet.balanceString)")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text("$0.00")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal)
    }
    
    private var currencyIcon: String {
        switch wallet.currencyCode {
        case "PLN": return "🇵🇱"
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "CHF": return "🇨🇭"
        case "JPY": return "🇯🇵"
        default: return "💰"
        }
    }
    
    private var currencyColor: Color {
        switch wallet.currencyCode {
        case "PLN": return .red
        case "USD": return .blue
        case "EUR": return .purple
        case "GBP": return .indigo
        case "CHF": return .red
        case "JPY": return .pink
        default: return .gray
        }
    }
    
    private var currencySymbol: String {
        switch wallet.currencyCode {
        case "PLN": return "zł"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "CHF": return "CHF"
        case "JPY": return "¥"
        default: return ""
        }
    }
}
