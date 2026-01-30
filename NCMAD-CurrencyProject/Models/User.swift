//
//  User.swift
//  NCMAD-CurrencyProject
//
//  Created by Ahmet Yada on 30/01/2026.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var email: String
    var name: String
    var createdAt: Date
    var isAuthenticated: Bool
    var authToken: String?
    
    init(id: UUID = UUID(), email: String, name: String, createdAt: Date = Date(), isAuthenticated: Bool = false, authToken: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.isAuthenticated = isAuthenticated
        self.authToken = authToken
    }
}
