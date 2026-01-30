//
//  Constants.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation

struct Constants {
    // API URLs
    struct API {
        // Will be updated with actual backend URL later
        static let baseURL = "http://localhost:3000/api"
        
        // NBP API URLs
        static let nbpBaseURL = "https://api.nbp.pl/api"
        static let nbpCurrentRates = "\(nbpBaseURL)/exchangerates/tables/A/?format=json"
        static func nbpHistoricalRates(currency: String, days: Int = 30) -> String {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "\(nbpBaseURL)/exchangerates/rates/A/\(currency)/\(formatter.string(from: startDate))/\(formatter.string(from: endDate))/?format=json"
        }
    }
    
    // Keychain keys
    struct Keychain {
        static let authToken = "authToken"
        static let userId = "userId"
    }
    
    // Default currencies
    struct Currencies {
        static let baseCurrency = "PLN"
        static let popularCurrencies = ["USD", "EUR", "GBP", "CHF", "JPY"]
    }
    
    // App colors (to be used in Views)
    struct Colors {
        // Will define custom colors here
    }
}
