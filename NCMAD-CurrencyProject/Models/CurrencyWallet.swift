//
//  CurrencyWallet.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import SwiftData

@Model
final class CurrencyWallet {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var currencyCode: String
    var currencyName: String
    var balance: Decimal
    var updatedAt: Date
    
    init(id: UUID = UUID(), userId: UUID, currencyCode: String, currencyName: String, balance: Decimal = 0, updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.currencyCode = currencyCode
        self.currencyName = currencyName
        self.balance = balance
        self.updatedAt = updatedAt
    }
    
    var balanceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: balance as NSDecimalNumber) ?? "0.00"
    }
}
