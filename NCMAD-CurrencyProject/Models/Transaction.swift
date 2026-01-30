//
//  Transaction.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable {
    case buy
    case sell
    case fund
}

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var fromCurrency: String
    var toCurrency: String
    var fromAmount: Decimal
    var toAmount: Decimal
    var exchangeRate: Decimal
    var timestamp: Date
    var type: TransactionType
    
    init(id: UUID = UUID(), userId: UUID, fromCurrency: String, toCurrency: String, fromAmount: Decimal, toAmount: Decimal, exchangeRate: Decimal, timestamp: Date = Date(), type: TransactionType) {
        self.id = id
        self.userId = userId
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.fromAmount = fromAmount
        self.toAmount = toAmount
        self.exchangeRate = exchangeRate
        self.timestamp = timestamp
        self.type = type
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var displayText: String {
        let fromAmountStr = (fromAmount as NSDecimalNumber).stringValue
        let toAmountStr = (toAmount as NSDecimalNumber).stringValue
        return "\(type.rawValue.capitalized): \(fromAmountStr) \(fromCurrency) → \(toAmountStr) \(toCurrency)"
    }
}
