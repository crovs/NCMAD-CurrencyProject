//
//  CurrencyRate.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation

// Models for NBP API responses
struct NBPTableResponse: Codable {
    let table: String
    let no: String
    let effectiveDate: String
    let rates: [CurrencyRate]
}

struct CurrencyRate: Codable, Identifiable {
    let currency: String
    let code: String
    let mid: Double
    
    var id: String { code }
    
    var formattedRate: String {
        String(format: "%.4f", mid)
    }
}

// Model for historical rates
struct NBPHistoricalResponse: Codable {
    let table: String
    let currency: String
    let code: String
    let rates: [HistoricalRate]
}

struct HistoricalRate: Codable, Identifiable {
    let no: String
    let effectiveDate: String
    let mid: Double
    
    var id: String { no }
    
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: effectiveDate)
    }
}
